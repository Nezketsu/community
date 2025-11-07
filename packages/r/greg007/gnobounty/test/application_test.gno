package gnobounty

import (
	"chain"
	"testing"

	"gno.land/p/nt/testutils"
)

func TestAddValidator(t *testing.T) {
	// Add a validator
	validator1 := testutils.TestAddress("validator1")
	testing.SetOriginCaller(validator1)
	AddValidator(cross)

	if !IsValidator(validator1) {
		t.Error("Validator should be active")
	}

	count := GetActiveValidatorCount()
	if count != 1 {
		t.Errorf("Expected 1 active validator, got %d", count)
	}
}

func TestApplyForBounty(t *testing.T) {
	// Setup validators
	validator1 := testutils.TestAddress("validator1")
	validator2 := testutils.TestAddress("validator2")
	validator3 := testutils.TestAddress("validator3")

	// Add validators if they don't exist
	if !IsValidator(validator1) {
		testing.SetOriginCaller(validator1)
		AddValidator(cross)
	}
	if !IsValidator(validator2) {
		testing.SetOriginCaller(validator2)
		AddValidator(cross)
	}
	if !IsValidator(validator3) {
		testing.SetOriginCaller(validator3)
		AddValidator(cross)
	}

	// Create a bounty
	testing.SetOriginCaller(testutils.TestAddress("creator"))
	testing.SetOriginSend(chain.Coins{chain.Coin{Denom: "ugnot", Amount: 5000000}})

	bountyID := CreateBounty(
		cross,
		"https://github.com/gnolang/gno/issues/1234",
		"Fix rendering issue",
	)

	// Apply for the bounty
	testing.SetOriginCaller(testutils.TestAddress("applicant"))
	testing.SetOriginSend(chain.Coins{})

	appID := ApplyForBounty(
		cross,
		bountyID,
		"https://github.com/gnolang/gno/pull/5678",
	)

	if appID != 1 {
		t.Errorf("Expected application ID 1, got %d", appID)
	}

	// Check application was created
	app := GetApplication(appID)
	if app == nil {
		t.Fatal("Application not found")
	}

	if app.Status != StatusPending {
		t.Error("Application should be pending")
	}

	if app.DAO == nil {
		t.Fatal("Application should have a DAO")
	}

	if app.ProposalID == 0 {
		t.Error("Application should have a proposal ID")
	}
}

func TestVoting(t *testing.T) {
	// Setup validators
	validator1 := testutils.TestAddress("validator1")
	validator2 := testutils.TestAddress("validator2")
	validator3 := testutils.TestAddress("validator3")

	// Add validators if they don't exist
	if !IsValidator(validator1) {
		testing.SetOriginCaller(validator1)
		AddValidator(cross)
	}
	if !IsValidator(validator2) {
		testing.SetOriginCaller(validator2)
		AddValidator(cross)
	}
	if !IsValidator(validator3) {
		testing.SetOriginCaller(validator3)
		AddValidator(cross)
	}

	// Create a bounty
	testing.SetOriginCaller(testutils.TestAddress("creator"))
	testing.SetOriginSend(chain.Coins{chain.Coin{Denom: "ugnot", Amount: 5000000}})

	bountyID := CreateBounty(
		cross,
		"https://github.com/gnolang/gno/issues/9999",
		"Add new feature",
	)

	// Apply for the bounty
	testing.SetOriginCaller(testutils.TestAddress("applicant"))
	testing.SetOriginSend(chain.Coins{})

	appID := ApplyForBounty(
		cross,
		bountyID,
		"https://github.com/gnolang/gno/pull/1111",
	)

	app := GetApplication(appID)

	// First validator approves
	testing.SetOriginCaller(validator1)
	Vote(cross, appID, "yes")

	app = GetApplication(appID)
	// With new DAO system requiring 3/3 votes, it should still be pending
	if app.Status != StatusPending {
		t.Error("Application should still be pending after 1 vote")
	}

	// Second validator approves
	testing.SetOriginCaller(validator2)
	Vote(cross, appID, "yes")

	app = GetApplication(appID)
	// Still pending with 2/3 votes
	if app.Status != StatusPending {
		t.Error("Application should still be pending after 2 votes")
	}

	// Third validator approves - this should trigger approval since we need 3/3
	testing.SetOriginCaller(validator3)
	Vote(cross, appID, "yes")

	app = GetApplication(appID)
	// With 3/3 yes votes, the proposal should execute and approve the application
	if app.Status != StatusApproved {
		t.Error("Application should be approved after 3 yes votes")
	}

	// Check that the bounty was claimed
	bounty := GetBounty(bountyID)
	if !bounty.IsClaimed {
		t.Error("Bounty should be claimed after approval")
	}
}

func TestInsufficientValidators(t *testing.T) {
	// Create a bounty without enough validators
	testing.SetOriginCaller(testutils.TestAddress("creator"))
	testing.SetOriginSend(chain.Coins{chain.Coin{Denom: "ugnot", Amount: 5000000}})

	bountyID := CreateBounty(
		cross,
		"https://github.com/gnolang/gno/issues/7777",
		"Test bounty",
	)

	// Try to apply without enough validators
	testing.SetOriginCaller(testutils.TestAddress("applicant"))
	testing.SetOriginSend(chain.Coins{})

	defer func() {
		if r := recover(); r == nil {
			t.Error("Expected panic when applying without enough validators")
		}
	}()

	ApplyForBounty(
		cross,
		bountyID,
		"https://github.com/gnolang/gno/pull/8888",
	)
}
