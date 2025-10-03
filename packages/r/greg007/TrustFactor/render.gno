package trustfactor

import (
    "std"
    "strconv"
    "strings"

    "gno.land/p/nt/ufmt"
    "gno.land/p/leon/svgbtn"
    "gno.land/p/moul/md"
)

// =============================================================================
// URL PARAMETER EXTRACTION
// =============================================================================

// extractSearchParam extracts the search parameter from URL query string
func extractSearchParam(path string) string {
    searchVal := ""

    if strings.Contains(path, "?") {
        parts := strings.Split(path, "?")
        if len(parts) > 1 {
            params := strings.Split(parts[1], "&")
            for _, param := range params {
                keyVal := strings.Split(param, "=")
                if len(keyVal) == 2 {
                    if keyVal[0] == "search" {
                        searchVal = keyVal[1]
                    }
                }
            }
        }
    }

    return searchVal
}

// =============================================================================
// SEARCH RESULTS RENDERING
// =============================================================================

// renderSearchResults displays search results for user queries
func renderSearchResults(query string) string {
    if query == "" {
        return "Please enter an address to search."
    }

    addr := std.Address(query)
    if _, exists := GetAllUsers()[addr]; exists {
        return renderUserProfile(string(addr))
    }

    result := md.H1("🔍 Search results for: " + md.InlineCode(query))

    var matches []std.Address
    for addr := range GetAllUsers() {
        addrStr := string(addr)
        if len(query) >= 4 && len(addrStr) >= len(query) {
            for i := 0; i <= len(addrStr)-len(query); i++ {
                if addrStr[i:i+len(query)] == query {
                    matches = append(matches, addr)
                    break
                }
            }
        }
    }

    if len(matches) == 0 {
        result += "❌ " + md.Bold("No users found") + "\n\n"
        result += md.Bold("Suggestions:") + "\n"
        suggestions := []string{
            "Check the address spelling",
            "Try with at least 4 characters",
            "User must be registered in the system",
        }
        result += md.BulletList(suggestions) + "\n"
    } else if len(matches) == 1 {
        return renderUserProfile(string(matches[0]))
    } else {
        result += "✅ " + md.Bold(strconv.Itoa(len(matches)) + " user(s) found:") + "\n\n"

        for _, addr := range matches {
            trust := GetTrustDetails(addr)
            compositeScore := calculateCompositeScore(trust)

            result += md.H3(string(addr))

            confidenceIcon := getConfidenceIcon(trust.Confidence)
            result += md.Bold("Trust Score: ") + ufmt.Sprintf("%.2f", compositeScore) + "/10.0 " + confidenceIcon + "\n"
            result += md.Bold("Votes: ") + strconv.Itoa(trust.TotalVotes) + " total\n\n"

            detailURL := "/r/greg007/trustfactor:" + string(addr)
            upvoteURL := "https://gno.land/r/greg007/trustfactor$help&func=Upvote&target=" + string(addr)
            downvoteURL := "https://gno.land/r/greg007/trustfactor$help&func=Downvote&target=" + string(addr)

            result += svgbtn.PrimaryButton(100, 30, "View Profile", detailURL) + " "
            result += svgbtn.SuccessButton(80, 30, "👍", upvoteURL) + " "
            result += svgbtn.DangerButton(80, 30, "👎", downvoteURL)
            result += "\n\n" + md.HorizontalRule()
        }
    }

    result += svgbtn.SmallButton(100, 30, "← Back", "/r/greg007/trustfactor")

    return result
}

// Render user profile
func renderUserProfile(path string) string {
    addr := std.Address(path)
    trust := GetTrustDetails(addr)

    if trust.Score == 0 && trust.LastUpdate == 0 {
        result := "# ❌ User Not Found\n\n"
        result += "No trust score found for address: `" + path + "`\n\n"
        result += "**Suggestions:**\n"
        result += "- Check that the address is correct (g1... format)\n"
        result += "- User must register first\n\n"

        backURL := "/r/greg007/trustfactor"
        result += svgbtn.PrimaryButton(150, 35, "← Back", backURL)
        return result
    }

    result := md.H2("👤 Profile: " + md.InlineCode(path))

    // Display SVG Widget

    result += md.H2("📊 Score")
    result += GenerateTrustWidget(addr) + "\n\n"
    scoreItems := []string{
        "**Confidence Level:** " + ufmt.Sprintf("%.1f%%", trust.Confidence*100),
    }
    result += md.BulletList(scoreItems) + "\n"

    result += md.H2("🗳️ Vote Statistics")
    voteItems := []string{
        "**Total Votes:** " + strconv.Itoa(trust.TotalVotes),
        "**Positive Votes:** 👍 " + strconv.Itoa(trust.PositiveVotes),
        "**Negative Votes:** 👎 " + strconv.Itoa(trust.NegativeVotes),
    }

    if trust.TotalVotes > 0 {
        positiveRatio := float64(trust.PositiveVotes) / float64(trust.TotalVotes) * 100
        voteItems = append(voteItems, "**Positive Ratio:** " + ufmt.Sprintf("%.1f%%", positiveRatio))
    }
    result += md.BulletList(voteItems) + "\n"

    result += md.H2("⏰ Time Information")

    timeItems := []string{
        "**Last Activity:** " + formatTimeAgo(trust.LastUpdate),
        "**Time Impact:** " + ufmt.Sprintf("%.1f%%", getTimeDecayFactor(trust.LastUpdate)*100) + " (score freshness)",
    }
    result += md.BulletList(timeItems) + "\n"

    // Recent vote history (last 5)
    history := GetVoteHistory(addr)
    if len(history) > 0 {
        result += md.H2("📋 Recent Vote History")
        startIdx := len(history) - 5
        if startIdx < 0 {
            startIdx = 0
        }

        historyItems := []string{}
        for i := len(history) - 1; i >= startIdx; i-- {
            vote := history[i]
            voteIcon := "👍"
            if vote.VoteType == "downvote" {
                voteIcon = "👎"
            }
            shortVoter := shortenAddress(string(vote.Voter), 12, 0) + "..."
            historyItems = append(historyItems, voteIcon + " by " + md.InlineCode(shortVoter) + " (weight: " + ufmt.Sprintf("%.1f", vote.Weight) + ")")
        }
        result += md.BulletList(historyItems) + "\n"
    }

    result += md.H2("🎯 Actions")
    upvoteURL := "https://gno.land/r/greg007/trustfactor$help&func=Upvote&target=" + string(addr)
    downvoteURL := "https://gno.land/r/greg007/trustfactor$help&func=Downvote&target=" + string(addr)
    backURL := "/r/greg007/trustfactor"

    result += svgbtn.SuccessButton(100, 35, "👍 Upvote", upvoteURL) + " "
    result += svgbtn.DangerButton(100, 35, "👎 Downvote", downvoteURL) + " "
    result += svgbtn.PrimaryButton(100, 35, "← Back", backURL)
    result += "\n\n"

    // Comments section
    result += md.H2("💬 Comments (" + strconv.Itoa(GetCommentCount(addr)) + ")")

    // Comment button
    commentURL := "https://gno.land/r/greg007/trustfactor$help&func=AddComment&target=" + string(addr) + "&text="
    result += svgbtn.PrimaryButton(150, 35, "💬 Leave a comment", commentURL)
    result += "\n\n"

    // Display existing comments
    comments := GetComments(addr)
    if len(comments) > 0 {
        result += md.Bold("Recent comments:") + "\n\n"

        // Limit to last 10 comments
        displayCount := 10
        if len(comments) < displayCount {
            displayCount = len(comments)
        }

        for i := 0; i < displayCount; i++ {
            comment := comments[i]
            timeStr := formatTimeAgoShort(comment.Timestamp)
            shortAuthor := shortenAddress(string(comment.Author), 12, 0) + "..."

            result += md.HorizontalRule()
            result += md.Bold(shortAuthor) + " - " + md.Italic(timeStr) + "\n\n"
            result += md.Blockquote(comment.Text)
        }
    } else {
        result += md.Italic("No comments yet. Be the first to comment!") + "\n\n"
    }

    return result
}

// =============================================================================
// MAIN PAGE RENDERING
// =============================================================================

// renderMainPageWithFilter displays the main page with optional search filtering
func renderMainPageWithFilter(filter string) string {
    result := md.H1("TrustFactor Registry")

    // Registration button
    registerURL := "https://gno.land/r/greg007/trustfactor$help&func=Register"
    result += svgbtn.SuccessButton(200, 40, "✓ Register (Score: 5.0)", registerURL)
    result += "\n\n"

    result += md.H2("🔍 Search Users")

    if filter != "" {
        result += md.Bold("🎯 Active filter for: ") + md.InlineCode(filter) + "\n\n"
        result += svgbtn.SmallButton(120, 30, "🗑️ Clear filter", "/r/greg007/trustfactor") + "\n\n"
    }

    result += `<gno-form>
<gno-input name="search" type="text" placeholder="Type part of the address to search..." />
</gno-form>

`

    result += md.Bold("💡 How to use search:") + "\n"
    searchSteps := []string{
        "Type part of the address in the field above",
        "Press Enter or click Submit",
        "URL will change to " + md.InlineCode("/r/greg007/trustfactor?search=YOUR_TERM"),
        "Page will reload with filtered results",
    }
    result += md.OrderedList(searchSteps) + "\n"

    // Popular users
    var topUsers []std.Address
    allUsers := GetAllUsers()
    for addr, trust := range allUsers {
        if trust.TotalVotes >= 3 {
            topUsers = append(topUsers, addr)
            if len(topUsers) >= 5 {
                break
            }
        }
    }

    if len(topUsers) > 0 {
        result += md.Bold("⭐ Popular Users:") + "\n\n"
        for i, addr := range topUsers {
            trust := GetTrustDetails(addr)
            shortAddr := shortenAddress(string(addr), 12, 0) + "..."
            userURL := "/r/greg007/trustfactor:" + string(addr)
            compositeScore := calculateCompositeScore(trust)

            result += svgbtn.TextButton(140, 30, ufmt.Sprintf("🔍 %s (%.1f)", shortAddr, compositeScore), userURL)
            if i < len(topUsers)-1 {
                result += " "
            }
        }
        result += "\n\n"
    }

    result += md.H2("Trust Scores for Addresses:")

    const USERS_PER_PAGE = 20
    offset := 0

    filteredAddrs, _ := FilterUsers(filter, USERS_PER_PAGE, offset)

    var users []UserDisplay
    for _, addr := range filteredAddrs {
        trust := GetTrustDetails(addr)
        users = append(users, UserDisplay{
            addr:           addr,
            trust:          trust,
            compositeScore: calculateCompositeScore(trust),
        })
    }

    if len(users) == 0 && filter != "" {
        result += "❌ " + md.Bold("No users found with filter: ") + md.InlineCode(filter) + "\n\n"
        result += "Try with a different part of the address or remove the filter.\n\n"
        return result
    }

    if len(users) == 0 {
        result += "No trust scores registered yet.\n\n"
        result += md.Italic("Click the button above to register!") + "\n"
        return result
    }

    for _, user := range users {
        addr := user.addr
        trust := user.trust
        compositeScore := user.compositeScore

        shortAddr := shortenAddress(string(addr), 12, 0) + "..."
        detailURL := "/r/greg007/trustfactor:" + string(addr)

        result += md.H3(svgbtn.TextButton(200, 30, "🔍 " + shortAddr, detailURL))

        confidenceIcon := getConfidenceIcon(trust.Confidence)
        result += md.Bold("Trust Score: ") + ufmt.Sprintf("%.2f", compositeScore) + "/10.0 " + confidenceIcon
        result += " " + md.Bold("Votes: ") + strconv.Itoa(trust.TotalVotes)

        if trust.TotalVotes > 0 {
            ratio := float64(trust.PositiveVotes) / float64(trust.TotalVotes) * 100
            result += " (" + ufmt.Sprintf("%.0f%% positive", ratio) + ")"
        }
        result += "\n\n"

        upvoteURL := "https://gno.land/r/greg007/trustfactor$help&func=Upvote&target=" + string(addr)
        downvoteURL := "https://gno.land/r/greg007/trustfactor$help&func=Downvote&target=" + string(addr)

        result += svgbtn.SuccessButton(80, 30, "👍", upvoteURL) + " "
        result += svgbtn.DangerButton(80, 30, "👎", downvoteURL) + " "
        result += svgbtn.SmallButton(80, 30, "Details", detailURL)
        result += "\n\n" + md.HorizontalRule()
    }

    return result
}