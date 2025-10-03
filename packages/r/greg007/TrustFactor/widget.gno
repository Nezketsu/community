package trustfactor

import (
	"std"

	"gno.land/p/demo/svg"
	"gno.land/p/nt/ufmt"
)

// =============================================================================
// SVG WIDGET GENERATION
// =============================================================================

// RenderWidget generates a standalone SVG widget for embedding (public function)
func RenderWidget(addr std.Address) string {
	return GenerateTrustWidget(addr)
}

// RenderCallerWidget generates a widget for the caller's address (no parameters needed)
// This is the recommended function for external realms
func RenderCallerWidget() string {
	caller := std.PreviousRealm().Address()
	return GenerateTrustWidget(caller)
}

// RenderOriginCallerWidget generates a widget for the origin caller (end user)
// Perfect for home realms that want to display visitor's trust score
func RenderOriginCallerWidget() string {
	originCaller := std.OriginCaller()
	return GenerateTrustWidget(originCaller)
}

// GenerateTrustWidget creates an SVG widget displaying trust score
func GenerateTrustWidget(addr std.Address) string {
	trust := GetTrustDetails(addr)
	compositeScore := calculateCompositeScore(trust)

	// Widget dimensions
	const (
		width       = 300
		height      = 150
		borderWidth = 3
	)
	padding := borderWidth / 2

	canvas := createCanvas(width, height)
	bg := createBackground(padding, width, height)
	addrText := createAddressText(addr, width)
	scoreDisplay := createScoreText(compositeScore, width, height)
	label := createLabelText(width, height)
	indicator := createConfidenceIndicator(trust.Confidence, width)

	canvas.Append(bg, addrText, scoreDisplay, label, indicator)

	return canvas.Render("TrustFactor Widget")
}

// createCanvas creates and configures the SVG canvas
func createCanvas(width, height int) *svg.Canvas {
	return svg.NewCanvas(width, height).
		WithViewBox(0, 0, width, height).
		AddStyle("text", "font-family:sans-serif;text-anchor:middle;dominant-baseline:middle;").
		AddStyle(".address", "font-size:12px;fill:#333;").
		AddStyle(".score", "font-size:48px;font-weight:bold;fill:#000;").
		AddStyle(".label", "font-size:14px;fill:#666;")
}

// createBackground creates the widget background with rounded corners
func createBackground(padding, width, height int) *svg.Rectangle {
	bg := svg.NewRectangle(padding, padding, width-(padding*2), height-(padding*2), "#ffffff")
	bg.RX = 15
	bg.RY = 15
	bg.Attr.Stroke = "#000000"
	bg.Attr.StrokeWidth = "3"
	return bg
}

// createAddressText creates the address text element
func createAddressText(addr std.Address, width int) *svg.Text {
	shortAddr := string(addr)
	if len(shortAddr) > 20 {
		shortAddr = shortenAddress(shortAddr, 10, 7)
	}
	addrText := svg.NewText(width/2, 30, shortAddr, "#333")
	addrText.Attr.Class = "address"
	return addrText
}

// createScoreText creates the trust score text element
func createScoreText(score float64, width, height int) *svg.Text {
	scoreText := ufmt.Sprintf("%.1f", score)
	scoreDisplay := svg.NewText(width/2, height/2+10, scoreText, "#000000")
	scoreDisplay.Attr.Class = "score"
	return scoreDisplay
}

// createLabelText creates the "Trust Score" label element
func createLabelText(width, height int) *svg.Text {
	label := svg.NewText(width/2, height-30, "Trust Score", "#666")
	label.Attr.Class = "label"
	return label
}

// createConfidenceIndicator creates the confidence indicator circle
func createConfidenceIndicator(confidence float64, width int) *svg.Circle {
	circleColor := getConfidenceColor(confidence)
	indicator := svg.NewCircle(width-30, 30, 6, circleColor)
	indicator.Attr.Stroke = circleColor
	indicator.Attr.StrokeWidth = "2"
	return indicator
}
