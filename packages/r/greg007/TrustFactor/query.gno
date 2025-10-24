package trustfactor

import "time"

// =============================================================================
// PUBLIC API FOR OTHER REALMS
// =============================================================================

// QueryTrustScore returns the calculated composite trust score for external use
func QueryTrustScore(addr address) (float64, bool) {
	value, exists := trustScores.Get(string(addr))
	if !exists {
		return 0.0, false
	}
	trust := value.(*TrustScore)
	return calculateCompositeScore(*trust), true
}

// QueryUserDetails returns comprehensive user information for external realms
func QueryUserDetails(addr address) (float64, int, float64, bool) {
	value, exists := trustScores.Get(string(addr))
	if !exists {
		return 0.0, 0, 0.0, false
	}
	trust := value.(*TrustScore)

	compositeScore := calculateCompositeScore(*trust)
	return compositeScore, trust.TotalVotes, trust.Confidence, true
}

// IsTrustedUser checks if a user meets a minimum trust threshold
func IsTrustedUser(addr address, minScore float64) bool {
	score, exists := QueryTrustScore(addr)
	return exists && score >= minScore
}

// GetUserRank returns the user's position in the trust leaderboard
func GetUserRank(addr address) (int, int, bool) {
	sortedUsers := GetSortedUsers()

	for i, userAddr := range sortedUsers {
		if userAddr == addr {
			return i + 1, len(sortedUsers), true
		}
	}

	return 0, len(sortedUsers), false
}

// GetTopTrustedUsers returns the N most trusted users
func GetTopTrustedUsers(limit int) []address {
	sortedUsers := GetSortedUsers()

	if limit > len(sortedUsers) {
		limit = len(sortedUsers)
	}

	result := make([]address, limit)
	copy(result, sortedUsers[:limit])
	return result
}

// GetScoreFreshness returns how many days since the user's last score update
func GetScoreFreshness(addr address) (int64, bool) {
	value, exists := trustScores.Get(string(addr))
	if !exists {
		return 0, false
	}
	trust := value.(*TrustScore)

	now := time.Now().Unix()
	daysSince := (now - trust.LastUpdate) / 86400
	return daysSince, true
}
