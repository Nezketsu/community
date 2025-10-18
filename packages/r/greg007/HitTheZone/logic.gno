// Package hitthezone implements a small gambling game on the Gno blockchain.
//
// Hit The Zone is a number guessing game where players bet on a range (min-max) within 1-100.
// A random number is generated on-chain, and if it falls within the player's chosen range,
// they win their bet multiplied by a calculated multiplier based on the range size.
//
// Game mechanics:
//   - Players choose a range (min-max) between 1 and 100
//   - Smaller ranges = higher multipliers (up to x100 for single number)
//   - Random number generated using entropy-based seeding
//   - Instant payout if player wins and realm has sufficient balance
//   - Automatic refund if payout fails
//
// Public functions:
//   - Game(min, max): Play the game with specified range
//   - Donate(): Support the game by donating to the owner
//   - GetRealmBalance(): View available funds for payouts
//   - GetTotalDonations(): View total donations received
//   - GetGameHistory(): View last 10 games played
//   - WithdrawAll(): Owner-only function to withdraw all funds
package hitthezone

import (
	"chain"
	"chain/banker"
	"chain/runtime"
	"math/rand"
	"strconv"
	"time"

	"gno.land/p/demo/entropy"
	"gno.land/p/moul/fifo"
)

var (
	lastRandomNumber int = 1
	counter          uint64
	gameHistory      = fifo.New(10)
	totalDonations   int64
	ownerAddress     = runtime.OriginCaller()
)

// Game executes the main game logic for Hit The Zone.
//
// Players specify a min and max range (min-max), and a random number between 1-100 is generated.
// If the random number falls within the specified range, the player wins and receives their
// bet amount multiplied by the calculated multiplier.
//
// Parameters:
//   - min: Minimum value of the range (must be >= 1 and < max)
//   - max: Maximum value of the range (must be <= 100 and > min)
//
// The function requires a transaction with attached ugnot coins as the bet amount (minimum 1 ugnot).
//
// Multiplier calculation: 100 / (max - min + 1)
// Example: Range 1-100 = x1.00, Range 50-50 = x100.00
//
// The function validates inputs, generates a random number, handles payouts (including refunds
// if insufficient realm balance), and records the game result in history.
//
// Events emitted:
//   - "PaymentSent": When winnings are successfully paid
//   - "PaymentFailed": When payment transaction fails
//   - "GamePayout": Detailed payout information (win/lose/refund)
//
// Panics if: min < 1, max > 100, min >= max, or bet amount < 1 ugnot.
func Game(cur realm, min int, max int) {
	runtime.AssertOriginCall()

	betAmount := validateGameInputs(min, max)
	multiplier := calculateMultiplier(min, max)
	won := playGame(min, max)

	caller := runtime.OriginCaller()
	result, actualWinAmount := handlePayout(won, betAmount, multiplier, caller)

	recordGame(caller, min, max, betAmount, actualWinAmount, multiplier, result)
}



// Donate allows users to send donations to the game owner.
//
// The donated amount is transferred directly to the owner's address and tracked
// in the totalDonations counter. This helps support the game and increase the
// realm's bankroll for future payouts.
//
// The function requires a transaction with attached ugnot coins as the donation amount.
//
// Events emitted:
//   - "Donation": Records the donation amount and donor address
//   - "PaymentSent": When donation is successfully transferred
//   - "PaymentFailed": If transfer fails
//
// Panics if: donation amount is 0 or negative, or if the transfer fails.
func Donate(cur realm) {
	runtime.AssertOriginCall()

	coins := banker.OriginSend()
	if len(coins) == 0 || coins[0].Amount <= 0 {
		panic("invalid donation")
	}

	success := safeSendCoins(ownerAddress, coins[0].Amount)
	if !success {
		panic("donation transfer failed")
	}

	totalDonations += coins[0].Amount

	chain.Emit("Donation",
		"amount", strconv.FormatInt(coins[0].Amount, 10),
		"from", runtime.OriginCaller().String())
}

// GetRealmBalance returns the current balance of ugnot held by the realm.
//
// This represents the total funds available for payouts to winning players.
// The balance increases through player losses and donations, and decreases
// through player wins.
//
// Returns: The realm's current ugnot balance as int64.
func GetRealmBalance() int64 {
	b := banker.NewBanker(banker.BankerTypeReadonly)
	coins := b.GetCoins(runtime.CurrentRealm().Address())
	return coins.AmountOf("ugnot")
}

// GetTotalDonations returns the total amount of donations received by the game.
//
// This counter tracks all donations sent to the owner via the Donate function.
// It does not include funds from player losses.
//
// Returns: The cumulative donation amount as int64.
func GetTotalDonations() int64 {
	return totalDonations
}

// GetGameHistory returns the last 10 games played, ordered from most recent to oldest.
//
// Each game record includes: player address, min/max range, random number generated,
// result (Win/Lose), bet amount, win amount, multiplier, and timestamp.
//
// The history is maintained in a FIFO queue with a maximum size of 10 entries.
// Older games are automatically removed when new games are played.
//
// Returns: A slice of GameHistory structs, maximum 10 entries, newest first.
func GetGameHistory() []GameHistory {
	history := make([]GameHistory, 0, 10)

	for i := 0; i < 10; i++ {
		item := gameHistory.Get(i)
		if item == nil {
			break
		}
		if gameData, ok := item.(GameHistory); ok {
			history = append(history, gameData)
		}
	}

	for i, j := 0, len(history)-1; i < j; i, j = i+1, j-1 {
		history[i], history[j] = history[j], history[i]
	}

	return history
}

// WithdrawAll allows the owner to withdraw all funds from the realm.
//
// This function transfers the entire realm balance to the owner's address.
// It is restricted to the realm owner (the address that deployed the realm).
//
// Security: Only the owner address (set at realm initialization) can call this function.
//
// Events emitted:
//   - "PaymentSent": When withdrawal is successful
//   - "PaymentFailed": If transfer fails
//
// Panics if:
//   - Caller is not the owner
//   - Realm balance is 0 or negative
//   - Transfer fails
func WithdrawAll(cur realm) {
	runtime.AssertOriginCall()

	if runtime.OriginCaller() != ownerAddress {
		panic("only owner can withdraw")
	}

	realmBalance := GetRealmBalance()
	if realmBalance <= 0 {
		panic("no funds to withdraw")
	}

	success := safeSendCoins(ownerAddress, realmBalance)
	if !success {
		panic("withdrawal failed")
	}
}

// calculateMultiplier calculates the payout multiplier based on the chosen range.
//
// The multiplier is inversely proportional to the range size: smaller ranges
// offer higher multipliers, making single-number bets the most rewarding but riskiest.
//
// Formula: 100.0 / (max - min + 1)
//
// Examples:
//   - Range 1-100 (full range): x1.00 multiplier
//   - Range 1-50 (half range): x2.00 multiplier
//   - Range 45-55 (11 numbers): x9.09 multiplier
//   - Range 50-50 (single number): x100.00 multiplier
//
// Parameters:
//   - min: Minimum value of the range
//   - max: Maximum value of the range
//
// Returns: The calculated multiplier as float64, or 0.0 if range is invalid.
func calculateMultiplier(min, max int) float64 {
	if min < 0 || max > 100 || min > max {
		return 0.0
	}
	rangeSize := max - min + 1
	return 100.0 / float64(rangeSize)
}


// generateRandom generates a random number between 1 and 100 using entropy-based seeding.
// The generated number is stored in the global lastRandomNumber variable.
func generateRandom() {
	counter++
	seed1 := uint64(entropy.New().Seed())
	seed2 := uint64(entropy.New().Seed())

	r := rand.New(rand.NewPCG(seed1, seed2))
	lastRandomNumber = r.IntN(100) + 1
}

// safeSendCoins safely sends coins to a recipient with error handling and event emission.
// It returns true if the transfer was successful, false otherwise.
// Failed transfers are logged via events and recovered from panics.
func safeSendCoins(recipient address, amount int64) bool {
	defer func() {
		if r := recover(); r != nil {
			chain.Emit("PaymentFailed",
				"recipient", recipient.String(),
				"amount", strconv.FormatInt(amount, 10),
				"reason", "transaction_failed")
		}
	}()

	if amount <= 0 {
		return false
	}

	b := banker.NewBanker(banker.BankerTypeRealmSend)
	coins := chain.NewCoins(chain.NewCoin("ugnot", amount))
	b.SendCoins(runtime.CurrentRealm().Address(), recipient, coins)

	chain.Emit("PaymentSent",
		"recipient", recipient.String(),
		"amount", strconv.FormatInt(amount, 10),
		"timestamp", strconv.FormatInt(time.Now().Unix(), 10))

	return true
}

// recordGame records the game result in the game history.
// History is stored in a FIFO queue that keeps the last 10 games.
func recordGame(player address, min, max int, betAmount, winAmount int64, multiplier float64, result string) {
	game := GameHistory{
		Player:       player,
		Min:          min,
		Max:          max,
		RandomNumber: lastRandomNumber,
		Result:       result,
		BetAmount:    betAmount,
		WinAmount:    winAmount,
		Multiplier:   multiplier,
		Timestamp:    time.Now(),
	}

	gameHistory.Append(game)
}

// validateGameInputs validates all game inputs and returns the bet amount.
// It checks that min >= 1, max <= 100, min < max, and bet amount >= 1 ugnot.
// Panics if any validation fails.
func validateGameInputs(min, max int) int64 {
	if min < 1 {
		panic("min must be >= 1")
	}
	if max > 100 {
		panic("max must be <= 100")
	}
	if min >= max {
		panic("min must be < max")
	}

	coins := banker.OriginSend()
	betAmount := int64(0)
	if len(coins) > 0 {
		betAmount = coins[0].Amount
	}

	if betAmount < 1 {
		panic("minimum bet is 1 ugnot")
	}

	return betAmount
}

// playGame generates a random number and checks if it falls within the player's range.
// Returns true if the player won, false otherwise.
func playGame(min, max int) bool {
	generateRandom()
	return lastRandomNumber >= min && lastRandomNumber <= max
}

// handlePayout handles all payout logic and returns the result message and actual payout amount.
// If the player won, it attempts to pay winnings based on the multiplier.
// If insufficient funds exist, it refunds the bet. All outcomes are logged via events.
// Uses early returns to minimize gas costs.
func handlePayout(won bool, betAmount int64, multiplier float64, caller address) (string, int64) {
	if !won {
		return "Lose", 0
	}

	currentBalance := GetRealmBalance()

	if currentBalance < betAmount {
		return "Win (House broke - no payout)", 0
	}

	winAmount := int64(float64(betAmount) * multiplier)

	if currentBalance < winAmount {
		safeSendCoins(caller, betAmount)
		chain.Emit("GamePayout",
			"player", caller.String(),
			"type", "refund_insufficient_funds",
			"bet_amount", strconv.FormatInt(betAmount, 10),
			"refund_amount", strconv.FormatInt(betAmount, 10),
			"required_amount", strconv.FormatInt(winAmount, 10))
		return "Win (Insufficient funds - refunded)", betAmount
	}

	return handleWinPayout(caller, betAmount, winAmount, multiplier)
}

// handleWinPayout attempts to pay the full winnings to the player.
// If payment fails, it refunds the bet instead.
func handleWinPayout(caller address, betAmount, winAmount int64, multiplier float64) (string, int64) {
	if !safeSendCoins(caller, winAmount) {
		safeSendCoins(caller, betAmount)
		chain.Emit("GamePayout",
			"player", caller.String(),
			"type", "refund_after_failed_payout",
			"bet_amount", strconv.FormatInt(betAmount, 10),
			"refund_amount", strconv.FormatInt(betAmount, 10))
		return "Win (Payment failed - refunded)", betAmount
	}

	chain.Emit("GamePayout",
		"player", caller.String(),
		"type", "win_payout",
		"bet_amount", strconv.FormatInt(betAmount, 10),
		"win_amount", strconv.FormatInt(winAmount, 10),
		"multiplier", strconv.FormatFloat(multiplier, 'f', 2, 64))
	return "Win", winAmount
}