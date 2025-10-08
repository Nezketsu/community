package hitthezone

import (
	"time"
)

// GameHistory represents a single game record in the Hit The Zone game.
//
// It contains all information about a player's game including the chosen range,
// the random number generated, bet and win amounts, outcome, and timestamp.
//
// This struct is used to maintain a history of the last 10 games played,
// which can be retrieved via GetGameHistory() and is displayed in the realm's UI.
//
// Fields:
//   - Player: Address of the player who placed the bet
//   - Min: Minimum value of the chosen range (1-100)
//   - Max: Maximum value of the chosen range (1-100)
//   - RandomNumber: The random number generated (1-100)
//   - Result: Game outcome ("Win", "Lose", "Win (refunded)", etc.)
//   - BetAmount: Amount wagered in ugnot
//   - WinAmount: Amount won/refunded in ugnot (0 if lost)
//   - Multiplier: Payout multiplier applied to the bet
//   - Timestamp: When the game was played
type GameHistory struct {
	Player       address   // Address of the player
	Min          int       // Minimum value of range (1-100)
	Max          int       // Maximum value of range (1-100)
	RandomNumber int       // Random number generated (1-100)
	Result       string    // Game outcome
	BetAmount    int64     // Bet amount in ugnot
	WinAmount    int64     // Win/refund amount in ugnot
	Multiplier   float64   // Payout multiplier
	Timestamp    time.Time // Game timestamp
}
