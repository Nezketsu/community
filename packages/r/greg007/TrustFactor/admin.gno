package trustfactor

import (
	"strings"

	"gno.land/p/nt/ownable"
)

// =============================================================================
// ADMIN FUNCTIONS (OWNER ONLY)
// =============================================================================

// RemoveUser removes a malicious user from the system (emergency function)
func RemoveUser(cur realm, target address) {
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

// GetOwnable returns the ownable object for ownership management
func GetOwnable() *ownable.Ownable {
	return owner
}
