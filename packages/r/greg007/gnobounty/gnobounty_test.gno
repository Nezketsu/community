package gnobounty

import (
	"chain"
	"testing"

	"gno.land/p/nt/testutils"
)

func TestCreateBounty(t *testing.T) {
	// Setup test environment
	testing.SetOriginCaller(testutils.TestAddress("alice"))

	// Send 5 GNOT with the bounty
	testing.SetOriginSend(chain.Coins{chain.Coin{Denom: "ugnot", Amount: 5000000}})

	// Create a bounty
	bountyID := CreateBounty(
		cross,
		"https://github.com/gnolang/gno/issues/1234",
		"Fix the rendering issue in the GRC20 token display",
	)

	if bountyID != 1 {
		t.Errorf("Expected bounty ID 1, got %d", bountyID)
	}

	// Check bounty was created
	bounty := GetBounty(bountyID)
	if bounty == nil {
		t.Fatal("Bounty not found")
	}

	if bounty.Amount != 5000000 {
		t.Errorf("Expected amount 5000000, got %d", bounty.Amount)
	}

	if bounty.IsClaimed {
		t.Error("Bounty should not be claimed yet")
	}
}

func TestCreateBountyWithoutCoins(t *testing.T) {
	testing.SetOriginCaller(testutils.TestAddress("bob"))
	testing.SetOriginSend(chain.Coins{})

	defer func() {
		if r := recover(); r == nil {
			t.Error("Expected panic when creating bounty without coins")
		}
	}()

	CreateBounty(
		cross,
		"https://github.com/gnolang/gno/issues/5678",
		"Add new feature",
	)
}

func TestClaimBounty(t *testing.T) {
	// Alice creates a bounty
	testing.SetOriginCaller(testutils.TestAddress("alice"))
	testing.SetOriginSend(chain.Coins{chain.Coin{Denom: "ugnot", Amount: 3000000}})

	bountyID := CreateBounty(
		cross,
		"https://github.com/gnolang/gno/issues/9999",
		"Implement new API endpoint",
	)

	// Alice approves Bob as claimer
	claimerAddr := testutils.TestAddress("bob")
	ClaimBounty(cross, bountyID, claimerAddr)

	// Check bounty is claimed
	bounty := GetBounty(bountyID)
	if !bounty.IsClaimed {
		t.Error("Bounty should be claimed")
	}

	if bounty.Claimer != claimerAddr {
		t.Errorf("Expected claimer %s, got %s", claimerAddr, bounty.Claimer)
	}
}

func TestCancelBounty(t *testing.T) {
	// Alice creates a bounty
	testing.SetOriginCaller(testutils.TestAddress("alice"))
	testing.SetOriginSend(chain.Coins{chain.Coin{Denom: "ugnot", Amount: 2000000}})

	bountyID := CreateBounty(
		cross,
		"https://github.com/gnolang/gno/issues/7777",
		"Update documentation",
	)

	// Alice cancels the bounty
	CancelBounty(cross, bountyID)

	// Check bounty is removed
	bounty := GetBounty(bountyID)
	if bounty != nil {
		t.Error("Bounty should be removed after cancellation")
	}
}

func TestListBounties(t *testing.T) {
	// Create multiple bounties
	testing.SetOriginCaller(testutils.TestAddress("alice"))
	testing.SetOriginSend(chain.Coins{chain.Coin{Denom: "ugnot", Amount: 1000000}})

	CreateBounty(cross, "https://github.com/gnolang/gno/issues/111", "Bug fix 1")

	testing.SetOriginSend(chain.Coins{chain.Coin{Denom: "ugnot", Amount: 2000000}})
	CreateBounty(cross, "https://github.com/gnolang/gno/issues/222", "Feature 2")

	// Get list of bounties
	list := ListBounties()

	if list == "No bounties available" {
		t.Error("Expected bounties to be listed")
	}
}
