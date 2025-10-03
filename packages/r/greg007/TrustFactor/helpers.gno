package trustfactor

import (
	"strconv"
	"time"
)

// =============================================================================
// TIME FORMATTING HELPERS
// =============================================================================

// formatTimeAgo formats a Unix timestamp into a human-readable "time ago" string
func formatTimeAgo(timestamp int64) string {
	now := time.Now().Unix()
	daysSince := (now - timestamp) / 86400

	if daysSince == 0 {
		return "Today"
	}
	if daysSince == 1 {
		return "1 day ago"
	}
	if daysSince < 7 {
		return strconv.FormatInt(daysSince, 10) + " days ago"
	}
	if daysSince < 30 {
		weeks := daysSince / 7
		return strconv.FormatInt(weeks, 10) + " week(s) ago"
	}
	if daysSince < 365 {
		months := daysSince / 30
		return strconv.FormatInt(months, 10) + " month(s) ago"
	}

	years := daysSince / 365
	return strconv.FormatInt(years, 10) + " year(s) ago"
}

// formatTimeAgoShort formats a Unix timestamp into a short "time ago" string
func formatTimeAgoShort(timestamp int64) string {
	now := time.Now().Unix()
	daysSince := (now - timestamp) / 86400

	if daysSince == 0 {
		return "today"
	}
	if daysSince == 1 {
		return "1 day ago"
	}
	if daysSince < 7 {
		return strconv.FormatInt(daysSince, 10) + " days ago"
	}
	if daysSince < 30 {
		weeks := daysSince / 7
		return strconv.FormatInt(weeks, 10) + " week(s) ago"
	}

	months := daysSince / 30
	return strconv.FormatInt(months, 10) + " month(s) ago"
}

// =============================================================================
// ADDRESS FORMATTING HELPERS
// =============================================================================

// shortenAddress shortens a long address for display
func shortenAddress(addr string, prefixLen, suffixLen int) string {
	if len(addr) <= prefixLen+suffixLen {
		return addr
	}
	return addr[:prefixLen] + "..." + addr[len(addr)-suffixLen:]
}

// =============================================================================
// CONFIDENCE ICON HELPERS
// =============================================================================

// getConfidenceIcon returns an emoji icon based on confidence level
func getConfidenceIcon(confidence float64) string {
	if confidence >= 0.8 {
		return "🟢"
	}
	if confidence >= 0.5 {
		return "🟡"
	}
	return "🔴"
}

// getConfidenceColor returns a color based on confidence level (for SVG)
func getConfidenceColor(confidence float64) string {
	if confidence >= 0.8 {
		return "#000000" // black
	}
	if confidence >= 0.5 {
		return "#666666" // dark gray
	}
	return "#CCCCCC" // light gray
}
