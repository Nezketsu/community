package gnobounty

import (
	"gno.land/p/nt/avl"
	"gno.land/p/nt/ufmt"
)

// LeaderboardEntry holds the stats for a user
type LeaderboardEntry struct {
	Address              address
	BountiesCreated      int
	BountiesApplied      int
	ValidationsPerformed int
	Score                int
}

// GetLeaderboard aggregates stats for all users
func GetLeaderboard() []LeaderboardEntry {
	var stats avl.Tree // address -> *LeaderboardEntry

	// Count bounties created (10 points)
	bounties.Iterate("", "", func(key string, value interface{}) bool {
		if value == nil {
			return false
		}
		bounty, ok := value.(*Bounty)
		if !ok || bounty == nil {
			return false
		}
		entry := getEntry(&stats, bounty.Creator)
		entry.BountiesCreated++
		entry.Score += 10
		return false
	})

	// Count applications and validations
	applications.Iterate("", "", func(key string, value interface{}) bool {
		if value == nil {
			return false
		}
		app, ok := value.(*Application)
		if !ok || app == nil {
			return false
		}

		// Only count approved applications (20 points)
		if app.Status == StatusApproved {
			entry := getEntry(&stats, app.Applicant)
			entry.BountiesApplied++
			entry.Score += 20
		}

		// Count validations from local record (5 points)
		for _, vote := range app.Votes {
			entry := getEntry(&stats, vote.Voter)
			entry.ValidationsPerformed++
			entry.Score += 5
		}

		return false
	})

	// Convert tree to slice
	var result []LeaderboardEntry
	stats.Iterate("", "", func(key string, value interface{}) bool {
		entry := value.(*LeaderboardEntry)
		result = append(result, *entry)
		return false
	})

	// Sort by Score descending
	// Manual bubble sort since sort.Slice is not available
	for i := 0; i < len(result)-1; i++ {
		for j := 0; j < len(result)-i-1; j++ {
			if result[j].Score < result[j+1].Score {
				// Swap
				result[j], result[j+1] = result[j+1], result[j]
			}
		}
	}

	return result
}

// RenderLeaderboard renders the leaderboard page
func RenderLeaderboard() string {
	entries := GetLeaderboard()

	output := "# 🏆 Community Leaderboard\n\n"
	output += "Top contributors to the GnoBounty ecosystem.\n\n"
	output += "**Scoring:** Bounty Creation (10pts) | Approved Application (20pts) | Validation (5pts)\n\n"

	output += "| Rank | User | Score | 💰 Bounties | 📝 Applications | ⚖️ Validations |\n"
	output += "|---|---|---|---|---|---|\n"

	for i, entry := range entries {
		rank := ""
		switch i {
		case 0:
			rank = "🥇"
		case 1:
			rank = "🥈"
		case 2:
			rank = "🥉"
		default:
			rank = ufmt.Sprintf("%d", i+1)
		}

		output += ufmt.Sprintf("| %s | %s | **%d** | %d | %d | %d |\n",
			rank,
			entry.Address,
			entry.Score,
			entry.BountiesCreated,
			entry.BountiesApplied,
			entry.ValidationsPerformed,
		)
	}

	if len(entries) == 0 {
		output += "\nNo activity recorded yet."
	}

	return output
}

func getEntry(stats *avl.Tree, addr address) *LeaderboardEntry {
	key := string(addr)
	val, ok := stats.Get(key)
	if !ok {
		entry := &LeaderboardEntry{Address: addr}
		stats.Set(key, entry)
		return entry
	}
	return val.(*LeaderboardEntry)
}
