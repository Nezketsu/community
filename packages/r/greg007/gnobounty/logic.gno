package gnobounty

import (
	"chain"
	"chain/banker"
	"chain/runtime"
	"time"

	"gno.land/p/nt/ufmt"
)

// CreateBounty creates a new bounty post
// issueURL: link to the GitHub issue or other issue tracker
// description: description of what needs to be done
// Caller must send GNOT tokens with this transaction
func CreateBounty(_ realm, issueURL, description string) uint64 {
	// Validate inputs
	if issueURL == "" {
		panic("issue URL cannot be empty")
	}
	if description == "" {
		panic("description cannot be empty")
	}

	// Get the sent coins
	sent := banker.OriginSend()
	if len(sent) == 0 {
		panic("no coins sent with bounty")
	}

	// Find GNOT amount
	var gnotAmount int64
	for _, coin := range sent {
		if coin.Denom == "ugnot" {
			gnotAmount = coin.Amount
			break
		}
	}

	if gnotAmount < minimumBounty {
		panic(ufmt.Sprintf("bounty amount must be at least %d ugnot", minimumBounty))
	}

	// Create bounty
	bountyCount++
	bounty := &Bounty{
		ID:          bountyCount,
		IssueURL:    issueURL,
		Description: description,
		Amount:      gnotAmount,
		Creator:     runtime.OriginCaller(),
		CreatedAt:   time.Now(),
		IsClaimed:   false,
	}

	// Store bounty
	bounties.Set(ufmt.Sprintf("%d", bountyCount), bounty)

	return bountyCount
}

// ClaimBounty allows someone to claim a bounty
// Only the creator can approve and transfer funds
func ClaimBounty(_ realm, id uint64, claimer address) {
	caller := runtime.OriginCaller()

	bounty := GetBounty(id)
	if bounty == nil {
		panic("bounty not found")
	}

	if bounty.IsClaimed {
		panic("bounty already claimed")
	}

	if caller != bounty.Creator {
		panic("only bounty creator can approve claims")
	}

	if claimer == "" {
		panic("claimer address cannot be empty")
	}

	// Mark as claimed
	bounty.IsClaimed = true
	bounty.Claimer = claimer
	bounty.ClaimedAt = time.Now()

	// Transfer bounty amount to claimer
	bnk := banker.NewBanker(banker.BankerTypeRealmSend)
	send := chain.Coins{chain.Coin{Denom: "ugnot", Amount: bounty.Amount}}
	pkgAddr := chain.PackageAddress("gno.land/r/greg007/gnobounty")
	bnk.SendCoins(pkgAddr, claimer, send)
}

// CancelBounty allows creator to cancel and get refund
func CancelBounty(_ realm, id uint64) {
	caller := runtime.OriginCaller()

	bounty := GetBounty(id)
	if bounty == nil {
		panic("bounty not found")
	}

	if bounty.IsClaimed {
		panic("cannot cancel claimed bounty")
	}

	if caller != bounty.Creator {
		panic("only bounty creator can cancel")
	}

	// Refund the creator
	bnk := banker.NewBanker(banker.BankerTypeRealmSend)
	send := chain.Coins{chain.Coin{Denom: "ugnot", Amount: bounty.Amount}}
	pkgAddr := chain.PackageAddress("gno.land/r/greg007/gnobounty")
	bnk.SendCoins(pkgAddr, bounty.Creator, send)

	// Remove bounty
	bounties.Remove(ufmt.Sprintf("%d", id))
}
