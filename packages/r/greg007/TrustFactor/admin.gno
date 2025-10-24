package trustfactor

import "strings"

// =============================================================================
// ADMIN FUNCTIONS (OWNER ONLY)
// =============================================================================

// RemoveUser removes a malicious user from the system (emergency function)
func RemoveUser(target address) {
	owner.AssertOwnedByCurrent()

	trustScores.Remove(string(target))
	voteHistory.Remove(string(target))

	// Clean up all votes involving the target user
	keysToRemove := []string{}
	userVotes.Iterate("", "", func(key string, value interface{}) bool {
		if strings.Contains(key, string(target)) {
			keysToRemove = append(keysToRemove, key)
		}
		return false
	})
	for _, key := range keysToRemove {
		userVotes.Remove(key)
	}

	totalUsers--
	invalidateCache()
}

// TransferOwnership transfers contract ownership to a new address
func TransferOwnership(newOwner address) error {
	return owner.TransferOwnership(newOwner)
}

// DropOwnership removes the owner, effectively disabling all admin functions
func DropOwnership() error {
	return owner.DropOwnershipByCurrent()
}

// Owner returns the current owner address
func Owner() address {
	return owner.Owner()
}
