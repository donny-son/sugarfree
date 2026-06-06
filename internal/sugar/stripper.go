package sugar

import "github.com/dlclark/regexp2"

// The strippers are deliberately a near-verbatim port of the Swift
// `SugarStripper` ICU patterns. Go's stdlib regexp (RE2) lacks lookbehind,
// lookahead, and backreferences — which the italic and HTML-heading rules need —
// so we use github.com/dlclark/regexp2 (a .NET-compatible engine) for parity.
//
// Flag parity with Swift is load-bearing:
//   - HTML patterns: case-insensitive, NOT dotall (so `.` doesn't cross newlines).
//   - Plain-text patterns: case-sensitive; only the heading rule is multiline.

func mustCompile(pattern string, opts regexp2.RegexOptions) *regexp2.Regexp {
	return regexp2.MustCompile(pattern, opts)
}

// replaceAll mirrors Swift's replacingOccurrences(of:with:options:.regularExpression):
// a global, non-overlapping, left-to-right replace. On the (compile-time-impossible)
// error path it returns the input unchanged.
func replaceAll(re *regexp2.Regexp, input, repl string) string {
	out, err := re.Replace(input, repl, -1, -1)
	if err != nil {
		return input
	}
	return out
}

// MARK: HTML patterns (case-insensitive, no dotall — matches Swift).

var (
	htmlBoldTags   = []*regexp2.Regexp{mustCompile(`<strong[^>]*>(.*?)</strong>`, regexp2.IgnoreCase), mustCompile(`<b[^>]*>(.*?)</b>`, regexp2.IgnoreCase)}
	htmlBoldStyle  = mustCompile(`font-weight\s*:\s*[^;"']+;?`, regexp2.IgnoreCase)
	htmlItalicTags = []*regexp2.Regexp{mustCompile(`<em[^>]*>(.*?)</em>`, regexp2.IgnoreCase), mustCompile(`<i[^>]*>(.*?)</i>`, regexp2.IgnoreCase)}
	htmlItalicSty  = mustCompile(`font-style\s*:\s*italic\s*;?`, regexp2.IgnoreCase)
	htmlUnderTags  = []*regexp2.Regexp{mustCompile(`<u[^>]*>(.*?)</u>`, regexp2.IgnoreCase)}
	htmlUnderSty   = mustCompile(`text-decoration(?:-line)?\s*:\s*underline\s*;?`, regexp2.IgnoreCase)
	htmlStrikeTags = []*regexp2.Regexp{mustCompile(`<s[^>]*>(.*?)</s>`, regexp2.IgnoreCase), mustCompile(`<del[^>]*>(.*?)</del>`, regexp2.IgnoreCase), mustCompile(`<strike[^>]*>(.*?)</strike>`, regexp2.IgnoreCase)}
	htmlStrikeSty  = mustCompile(`text-decoration(?:-line)?\s*:\s*line-through\s*;?`, regexp2.IgnoreCase)
	htmlHeading    = mustCompile(`<h([1-6])[^>]*>(.*?)</h\1>`, regexp2.IgnoreCase)
)

// StripHTML unwraps tags and drops inline-style declarations for each enabled
// sugar. Best-effort regex (no DOM parse), matching the documented caveats.
func StripHTML(html string, sugars Set) string {
	result := html

	unwrap := func(sug Sugar, tags []*regexp2.Regexp, styles ...*regexp2.Regexp) {
		if !sugars.Has(sug) {
			return
		}
		for _, re := range tags {
			result = replaceAll(re, result, "$1")
		}
		for _, re := range styles {
			result = replaceAll(re, result, "")
		}
	}

	unwrap(Bold, htmlBoldTags, htmlBoldStyle)
	unwrap(Italic, htmlItalicTags, htmlItalicSty)
	unwrap(Underline, htmlUnderTags, htmlUnderSty)
	unwrap(Strikethrough, htmlStrikeTags, htmlStrikeSty)

	// Headings: unwrap <h1>–<h6> to their inner text. The backreference ties the
	// close tag to the open level, so it keeps its own replacement ($2).
	if sugars.Has(Heading) {
		result = replaceAll(htmlHeading, result, "$2")
	}

	return result
}

// MARK: Plain-text / markdown patterns (case-sensitive; heading is multiline).

var (
	mdHeading = mustCompile(`(?m)^[ \t]{0,3}#{1,6}[ \t]+(.*?)(?:[ \t]+#+)?[ \t]*$`, regexp2.None)
	mdStrike  = mustCompile(`~~(.+?)~~`, regexp2.None)
	mdBold    = []*regexp2.Regexp{mustCompile(`\*\*(.+?)\*\*`, regexp2.None), mustCompile(`__(.+?)__`, regexp2.None)}
	// Italic: single * (not part of **), and _ only at non-alphanumeric boundaries
	// so snake_case identifiers survive.
	mdItalic = []*regexp2.Regexp{
		mustCompile(`(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)`, regexp2.None),
		mustCompile(`(?<![A-Za-z0-9])_(.+?)_(?![A-Za-z0-9])`, regexp2.None),
	}
)

// StripPlainText removes markdown markers for each enabled sugar. Underline has
// no markdown form, so it's skipped here. Bold runs before italic so `**` isn't
// half-consumed by the single-`*` rule.
func StripPlainText(text string, sugars Set) string {
	result := text

	apply := func(sug Sugar, res []*regexp2.Regexp) {
		if !sugars.Has(sug) {
			return
		}
		for _, re := range res {
			result = replaceAll(re, result, "$1")
		}
	}

	apply(Heading, []*regexp2.Regexp{mdHeading})
	apply(Strikethrough, []*regexp2.Regexp{mdStrike})
	apply(Bold, mdBold)
	apply(Italic, mdItalic)

	return result
}
