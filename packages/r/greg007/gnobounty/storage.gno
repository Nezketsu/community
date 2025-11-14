package gnobounty

import (
	"gno.land/p/nt/avl"
	"gno.land/p/nt/ufmt"
)

var (
	bounties      avl.Tree // uint64 -> *Bounty
	bountyCount   uint64
	minimumBounty int64 = 1000000 // 1 GNOT minimum

	applications     avl.Tree // uint64 -> *Application
	applicationCount uint64

	validators       avl.Tree      // address -> *Validator
	validatorList    []address     // List of validator addresses for random selection
	validatorsPerDAO int       = 3 // Number of validators per DAO vote
	requiredVotes    int       = 3 // Number of approvals needed (3/3)

	// Validator reward percentage (5% of bounty split among validators)
	validatorRewardPercent int64 = 5 // 5% of bounty goes to validators
)

// GetBounty returns a bounty by ID
func GetBounty(id uint64) *Bounty {
	bountyInterface, exists := bounties.Get(ufmt.Sprintf("%d", id))
	if !exists {
		return nil
	}
	return bountyInterface.(*Bounty)
}

// GetBountyCount returns the total number of bounties created
func GetBountyCount() uint64 {
	return bountyCount
}

// SetMinimumBounty allows setting minimum bounty amount (admin function)
func SetMinimumBounty(amount int64) {
	// In production, you'd want to add proper admin checks here
	minimumBounty = amount
}

// GetApplication returns an application by ID
func GetApplication(id uint64) *Application {
	appInterface, exists := applications.Get(ufmt.Sprintf("%d", id))
	if !exists {
		return nil
	}
	return appInterface.(*Application)
}

// GetApplicationCount returns the total number of applications
func GetApplicationCount() uint64 {
	return applicationCount
}

// IsValidator checks if an address is a validator
func IsValidator(addr address) bool {
	validatorInterface, exists := validators.Get(string(addr))
	if !exists {
		return false
	}
	validator := validatorInterface.(*Validator)
	return validator.Active
}

// GetValidator returns a validator by address
func GetValidator(addr address) *Validator {
	validatorInterface, exists := validators.Get(string(addr))
	if !exists {
		return nil
	}
	return validatorInterface.(*Validator)
}

// GetActiveValidatorCount returns the number of active validators
func GetActiveValidatorCount() int {
	count := 0
	validators.Iterate("", "", func(key string, value interface{}) bool {
		validator := value.(*Validator)
		if validator.Active {
			count++
		}
		return false
	})
	return count
}
