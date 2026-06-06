package sugar

import (
	"regexp"
	"strings"
)

// Format is the output style for the table → list transform.
type Format int

const (
	YAML Format = iota
	TOML
)

// trimWS trims spaces and tabs only — mirrors Swift's CharacterSet.whitespaces
// (which, unlike .whitespacesAndNewlines, excludes line breaks).
func trimWS(s string) string { return strings.Trim(s, " \t") }

// MARK: Markdown

// ConvertMarkdownTables replaces every Markdown pipe table in text with its
// converted form. Returns the rewritten text and the number of tables converted.
func ConvertMarkdownTables(text string, format Format) (string, int) {
	lines := strings.Split(text, "\n")
	var out []string
	count := 0
	i := 0

	for i < len(lines) {
		if headers, rows, end, ok := matchTable(lines, i); ok {
			out = append(out, render(headers, rows, format))
			count++
			i = end
		} else {
			out = append(out, lines[i])
			i++
		}
	}

	if count == 0 {
		return text, 0
	}
	return strings.Join(out, "\n"), count
}

// matchTable parses a GFM table starting at line `start`: a header row plus a
// `|---|---|` delimiter row whose column count matches. Pipes are required on the
// delimiter row so a bare `---` (setext heading / rule) is never a table.
func matchTable(lines []string, start int) (headers []string, rows [][]string, end int, ok bool) {
	if start+1 >= len(lines) {
		return nil, nil, 0, false
	}
	headerLine := lines[start]
	delimiterLine := lines[start+1]
	if !strings.Contains(headerLine, "|") || !strings.Contains(delimiterLine, "|") {
		return nil, nil, 0, false
	}
	if !isDelimiterRow(delimiterLine) {
		return nil, nil, 0, false
	}

	headers = splitRow(headerLine)
	if len(headers) == 0 {
		return nil, nil, 0, false
	}
	if len(splitRow(delimiterLine)) != len(headers) {
		return nil, nil, 0, false
	}

	i := start + 2
	for i < len(lines) {
		line := lines[i]
		if trimWS(line) == "" {
			break
		}
		if !strings.Contains(line, "|") {
			break
		}
		rows = append(rows, normalize(splitRow(line), len(headers)))
		i++
	}

	if len(rows) == 0 {
		return nil, nil, 0, false
	}
	return headers, rows, i, true
}

func isDelimiterRow(line string) bool {
	cells := splitRow(line)
	if len(cells) == 0 {
		return false
	}
	for _, c := range cells {
		if !isDelimiterCell(c) {
			return false
		}
	}
	return true
}

// isDelimiterCell is dashes with an optional leading/trailing alignment colon.
func isDelimiterCell(cell string) bool {
	chars := []rune(cell)
	if len(chars) == 0 {
		return false
	}
	if chars[0] == ':' {
		chars = chars[1:]
	}
	if len(chars) > 0 && chars[len(chars)-1] == ':' {
		chars = chars[:len(chars)-1]
	}
	if len(chars) == 0 {
		return false
	}
	for _, c := range chars {
		if c != '-' {
			return false
		}
	}
	return true
}

// splitRow splits a Markdown row into trimmed cells, honoring `\|` escapes and
// dropping the empty cells produced by optional outer pipes.
func splitRow(line string) []string {
	var cells []string
	var current strings.Builder
	escaped := false

	for _, ch := range line {
		switch {
		case escaped:
			if ch == '|' {
				current.WriteRune('|')
			} else {
				current.WriteRune('\\')
				current.WriteRune(ch)
			}
			escaped = false
		case ch == '\\':
			escaped = true
		case ch == '|':
			cells = append(cells, current.String())
			current.Reset()
		default:
			current.WriteRune(ch)
		}
	}
	if escaped {
		current.WriteRune('\\')
	}
	cells = append(cells, current.String())

	trimmed := make([]string, len(cells))
	for i, c := range cells {
		trimmed[i] = trimWS(c)
	}
	if len(trimmed) > 0 && trimmed[0] == "" {
		trimmed = trimmed[1:]
	}
	if len(trimmed) > 0 && trimmed[len(trimmed)-1] == "" {
		trimmed = trimmed[:len(trimmed)-1]
	}
	return trimmed
}

func normalize(cells []string, width int) []string {
	if len(cells) < width {
		out := make([]string, width)
		copy(out, cells)
		return out
	}
	if len(cells) > width {
		return cells[:width]
	}
	return cells
}

// MARK: HTML

var (
	reHTMLTable = regexp.MustCompile(`(?is)<table[^>]*>.*?</table>`)
	reHTMLRow   = regexp.MustCompile(`(?is)<tr[^>]*>(.*?)</tr>`)
	reHTMLCell  = regexp.MustCompile(`(?is)<t[dh][^>]*>(.*?)</t[dh]>`)
	reHTMLTags  = regexp.MustCompile(`<[^>]+>`)
	reWS        = regexp.MustCompile(`\s+`)
)

// ConvertHTMLTables replaces every <table>…</table> with a <pre> block holding
// the converted list, so rich paste targets receive the YAML/TOML instead.
func ConvertHTMLTables(html string, format Format) (string, int) {
	locs := reHTMLTable.FindAllStringIndex(html, -1)
	if len(locs) == 0 {
		return html, 0
	}

	result := html
	count := 0
	// Replace from the end so earlier match ranges stay valid as we mutate.
	for i := len(locs) - 1; i >= 0; i-- {
		loc := locs[i]
		tableHTML := html[loc[0]:loc[1]]
		headers, rows, ok := parseHTMLTable(tableHTML)
		if !ok || len(rows) == 0 {
			continue
		}
		converted := render(headers, rows, format)
		result = result[:loc[0]] + "<pre>" + escapeHTML(converted) + "</pre>" + result[loc[1]:]
		count++
	}

	if count == 0 {
		return html, 0
	}
	return result, count
}

func parseHTMLTable(table string) (headers []string, rows [][]string, ok bool) {
	var parsed [][]string
	for _, m := range reHTMLRow.FindAllStringSubmatch(table, -1) {
		var cells []string
		for _, cm := range reHTMLCell.FindAllStringSubmatch(m[1], -1) {
			cells = append(cells, cleanCell(cm[1]))
		}
		if len(cells) > 0 {
			parsed = append(parsed, cells)
		}
	}
	if len(parsed) == 0 || len(parsed[0]) == 0 {
		return nil, nil, false
	}
	headers = parsed[0]
	for _, body := range parsed[1:] {
		rows = append(rows, normalize(body, len(headers)))
	}
	return headers, rows, true
}

// cleanCell strips inner tags, decodes common entities, and collapses whitespace.
func cleanCell(raw string) string {
	s := reHTMLTags.ReplaceAllString(raw, "")
	s = decodeEntities(s)
	s = reWS.ReplaceAllString(s, " ")
	return strings.TrimSpace(s)
}

func decodeEntities(s string) string {
	// &amp; is decoded last so e.g. "&amp;lt;" doesn't collapse to "<".
	pairs := [][2]string{
		{"&lt;", "<"}, {"&gt;", ">"}, {"&quot;", "\""},
		{"&#39;", "'"}, {"&apos;", "'"}, {"&nbsp;", " "}, {"&amp;", "&"},
	}
	for _, p := range pairs {
		s = replaceCaseInsensitive(s, p[0], p[1])
	}
	return s
}

// replaceCaseInsensitive replaces all case-insensitive occurrences of old with
// new — mirrors Swift's replacingOccurrences(of:with:options:.caseInsensitive).
func replaceCaseInsensitive(s, old, new string) string {
	if old == "" {
		return s
	}
	re := regexp.MustCompile(`(?i)` + regexp.QuoteMeta(old))
	return re.ReplaceAllLiteralString(s, new)
}

func escapeHTML(s string) string {
	s = strings.ReplaceAll(s, "&", "&amp;")
	s = strings.ReplaceAll(s, "<", "&lt;")
	s = strings.ReplaceAll(s, ">", "&gt;")
	return s
}

// MARK: Rendering (YAML-/TOML-style, not spec-strict: keys/values emitted raw).

func render(headers []string, rows [][]string, format Format) string {
	if format == TOML {
		return renderTOML(headers, rows)
	}
	return renderYAML(headers, rows)
}

func renderYAML(headers []string, rows [][]string) string {
	var out []string
	for _, row := range rows {
		for col, header := range headers {
			value := ""
			if col < len(row) {
				value = row[col]
			}
			entry := header + ":"
			if value != "" {
				entry = header + ": " + value
			}
			if col == 0 {
				out = append(out, "- "+entry)
			} else {
				out = append(out, "  "+entry)
			}
		}
	}
	return strings.Join(out, "\n")
}

func renderTOML(headers []string, rows [][]string) string {
	var blocks []string
	for _, row := range rows {
		var lines []string
		for col, header := range headers {
			value := ""
			if col < len(row) {
				value = row[col]
			}
			line := header + " ="
			if value != "" {
				line = header + " = " + value
			}
			lines = append(lines, line)
		}
		blocks = append(blocks, strings.Join(lines, "\n"))
	}
	return strings.Join(blocks, "\n\n")
}
