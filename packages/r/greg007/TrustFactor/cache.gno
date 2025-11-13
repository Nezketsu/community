package trustfactor

import (
	"strings"
	"time"
)

// =============================================================================
// PERFORMANCE OPTIMIZATION - CACHING & SORTING
// =============================================================================

// invalidateCache clears the sorted user cache when data changes
func invalidateCache() {
	lastSortTime = 0
	sortedUsers = make([]address, 0)
}

// GetSortedUsers returns users sorted by composite score with caching
func GetSortedUsers() []address {
	now := time.Now().Unix()

	// Check if cache is still valid
	if now-lastSortTime < SORT_CACHE_TTL && len(sortedUsers) == totalUsers {
		return sortedUsers
	}

	// Rebuild cache if expired or invalid
	return rebuildSortCache()
}

// rebuildSortCache rebuilds the sorted user cache using optimized quicksort
func rebuildSortCache() []address {
	// Convert AVL tree to slice for sorting
	users := make([]address, 0, trustScores.Size())
	trustScores.Iterate("", "", func(key string, value interface{}) bool {
		users = append(users, address(key))
		return false
	})

	// Quicksort by composite score (descending)
	quickSortByScore(users, 0, len(users)-1)

	// Update cache
	sortedUsers = users
	lastSortTime = time.Now().Unix()
	totalUsers = len(users)

	return sortedUsers
}

// quickSortByScore implements quicksort algorithm for user addresses by composite score
func quickSortByScore(users []address, low, high int) {
	if low < high {
		pi := partitionByScore(users, low, high)
		quickSortByScore(users, low, pi-1)
		quickSortByScore(users, pi+1, high)
	}
}

// partitionByScore partitions the array for quicksort (descending order)
func partitionByScore(users []address, low, high int) int {
	pivotValue, _ := trustScores.Get(string(users[high]))
	pivotScore := calculateCompositeScore(*pivotValue.(*TrustScore))
	i := low - 1

	for j := low; j < high; j++ {
		currentValue, _ := trustScores.Get(string(users[j]))
		currentScore := calculateCompositeScore(*currentValue.(*TrustScore))
		if currentScore > pivotScore {
			i++
			users[i], users[j] = users[j], users[i]
		}
	}

	users[i+1], users[high] = users[high], users[i+1]
	return i + 1
}

// =============================================================================
// SEARCH AND FILTERING
// =============================================================================

// FilterUsers returns paginated and filtered user results
func FilterUsers(searchTerm string, limit int, offset int) ([]address, int) {
	if searchTerm == "" {
		sorted := GetSortedUsers()
		total := len(sorted)

		end := offset + limit
		if end > total {
			end = total
		}
		if offset > total {
			return []address{}, total
		}

		return sorted[offset:end], total
	}

	var filtered []address
	for _, addr := range GetSortedUsers() {
		addrStr := string(addr)
		if containsSubstring(addrStr, searchTerm) {
			filtered = append(filtered, addr)
		}
	}

	total := len(filtered)
	end := offset + limit
	if end > total {
		end = total
	}
	if offset > total {
		return []address{}, total
	}

	return filtered[offset:end], total
}

// containsSubstring checks if a string contains a substring (case-sensitive)
func containsSubstring(str, substr string) bool {
	return strings.Index(str, substr) >= 0
}

// GetPerformanceStats returns cache and performance statistics
func GetPerformanceStats() (int, int, int64) {
	return totalUsers, len(sortedUsers), lastSortTime
}
