package trustfactor

import (
	"gno.land/p/nt/avl"
	"gno.land/p/nt/ownable"
)

// =============================================================================
// GLOBAL STATE VARIABLES
// =============================================================================

var (
	// Main storage using AVL trees
	trustScores  *avl.Tree // Main storage for user trust scores (key: address, value: *TrustScore)
	userVotes    *avl.Tree // Tracks votes in "voter_target" format (key: string, value: bool)
	voteHistory  *avl.Tree // Historical vote records per user (key: address, value: []VoteHistory)
	userComments *avl.Tree // User comments storage using AVL tree (key: address, value: *avl.Tree)
	owner        *ownable.Ownable // Contract ownership management

	// Performance optimization cache
	sortedUsers  []address // Cached sorted user list
	lastSortTime int64     // Last cache update timestamp
	totalUsers   int       // Total registered users count
)

// =============================================================================
// CONSTANTS
// =============================================================================

const (
	MAX_HISTORY_SIZE = 50  // Maximum vote history entries per user
	SORT_CACHE_TTL   = 300 // Cache time-to-live in seconds
)

// =============================================================================
// INITIALIZATION
// =============================================================================

func init() {
	trustScores = avl.NewTree()
	userVotes = avl.NewTree()
	voteHistory = avl.NewTree()
	userComments = avl.NewTree()
	owner = ownable.NewWithAddress(address("g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5"))
}
