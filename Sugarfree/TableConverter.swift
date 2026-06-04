import Foundation

/// Converts tabular content — Markdown pipe tables and HTML `<table>` — into
/// YAML-style or TOML-style list items. Pure string logic (no AppKit) so it stays
/// unit-testable and reusable across representations. Output is *style*, not spec-strict:
/// values and keys are emitted raw (no quoting) for readability.
///
/// Mapping is **header-keyed list items**: the first row is treated as headers and
/// every following row becomes one list entry mapping `header: cell`. This is
/// lossless for any column count and avoids guessing which column is the "key".
/// Best-effort by design — regex-based HTML parsing (no DOM), like the strippers.
enum TableConverter {
    enum Format {
        case yaml
        case toml
    }

    // MARK: - Markdown

    /// Replaces every Markdown pipe table in `text` with its converted form.
    /// Returns the rewritten text and the number of tables converted (0 = unchanged).
    static func convertMarkdownTables(in text: String, format: Format) -> (String, Int) {
        let lines = text.components(separatedBy: "\n")
        var output: [String] = []
        var count = 0
        var i = 0

        while i < lines.count {
            if let table = matchTable(lines, at: i) {
                output.append(render(headers: table.headers, rows: table.rows, format: format))
                count += 1
                i = table.endIndex
            } else {
                output.append(lines[i])
                i += 1
            }
        }

        guard count > 0 else { return (text, 0) }
        return (output.joined(separator: "\n"), count)
    }

    private struct ParsedTable {
        let headers: [String]
        let rows: [[String]]
        /// Index of the first line *after* the table.
        let endIndex: Int
    }

    /// A GFM table starts with a header row and a `|---|---|` delimiter row whose
    /// column count matches. We require pipes on the delimiter row so a bare `---`
    /// (setext heading / horizontal rule) is never mistaken for a table.
    private static func matchTable(_ lines: [String], at start: Int) -> ParsedTable? {
        guard start + 1 < lines.count else { return nil }
        let headerLine = lines[start]
        let delimiterLine = lines[start + 1]
        guard headerLine.contains("|"), delimiterLine.contains("|") else { return nil }
        guard isDelimiterRow(delimiterLine) else { return nil }

        let headers = splitRow(headerLine)
        guard !headers.isEmpty else { return nil }
        guard splitRow(delimiterLine).count == headers.count else { return nil }

        var rows: [[String]] = []
        var i = start + 2
        while i < lines.count {
            let line = lines[i]
            if line.trimmingCharacters(in: .whitespaces).isEmpty { break }
            guard line.contains("|") else { break }
            rows.append(normalize(splitRow(line), to: headers.count))
            i += 1
        }

        guard !rows.isEmpty else { return nil }
        return ParsedTable(headers: headers, rows: rows, endIndex: i)
    }

    private static func isDelimiterRow(_ line: String) -> Bool {
        let cells = splitRow(line)
        guard !cells.isEmpty else { return false }
        return cells.allSatisfy(isDelimiterCell)
    }

    /// A delimiter cell is dashes with an optional leading/trailing alignment colon.
    private static func isDelimiterCell(_ cell: String) -> Bool {
        var chars = Array(cell)
        guard !chars.isEmpty else { return false }
        if chars.first == ":" { chars.removeFirst() }
        if chars.last == ":" { chars.removeLast() }
        guard !chars.isEmpty else { return false }
        return chars.allSatisfy { $0 == "-" }
    }

    /// Splits a Markdown row into trimmed cells, honoring `\|` escapes and dropping
    /// the empty cells produced by optional outer pipes.
    private static func splitRow(_ line: String) -> [String] {
        var cells: [String] = []
        var current = ""
        var escaped = false

        for ch in line {
            if escaped {
                if ch == "|" {
                    current.append("|")
                } else {
                    current.append("\\")
                    current.append(ch)
                }
                escaped = false
            } else if ch == "\\" {
                escaped = true
            } else if ch == "|" {
                cells.append(current)
                current = ""
            } else {
                current.append(ch)
            }
        }
        if escaped { current.append("\\") }
        cells.append(current)

        var trimmed = cells.map { $0.trimmingCharacters(in: .whitespaces) }
        if trimmed.first == "" { trimmed.removeFirst() }
        if trimmed.last == "" { trimmed.removeLast() }
        return trimmed
    }

    private static func normalize(_ cells: [String], to width: Int) -> [String] {
        if cells.count < width {
            return cells + Array(repeating: "", count: width - cells.count)
        }
        if cells.count > width {
            return Array(cells.prefix(width))
        }
        return cells
    }

    // MARK: - HTML

    /// Replaces every `<table>…</table>` with a `<pre>` block holding the converted
    /// list, so rich paste targets receive the YAML/TOML instead of the table.
    static func convertHTMLTables(in html: String, format: Format) -> (String, Int) {
        guard let regex = try? NSRegularExpression(pattern: "<table[^>]*>.*?</table>",
                                                   options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return (html, 0)
        }
        let ns = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return (html, 0) }

        let mutable = NSMutableString(string: html)
        var count = 0
        // Replace from the end so earlier match ranges stay valid as we mutate.
        for match in matches.reversed() {
            let tableHTML = ns.substring(with: match.range)
            guard let parsed = parseHTMLTable(tableHTML), !parsed.rows.isEmpty else { continue }
            let converted = render(headers: parsed.headers, rows: parsed.rows, format: format)
            mutable.replaceCharacters(in: match.range, with: "<pre>\(escapeHTML(converted))</pre>")
            count += 1
        }

        guard count > 0 else { return (html, 0) }
        return (mutable as String, count)
    }

    private static func parseHTMLTable(_ table: String) -> (headers: [String], rows: [[String]])? {
        let rowChunks = capturedGroups("<tr[^>]*>(.*?)</tr>", in: table)
        var parsed: [[String]] = []
        for chunk in rowChunks {
            let cells = capturedGroups("<t[dh][^>]*>(.*?)</t[dh]>", in: chunk).map(cleanCell)
            if !cells.isEmpty { parsed.append(cells) }
        }
        guard let headers = parsed.first, !headers.isEmpty else { return nil }
        let body = parsed.dropFirst().map { normalize($0, to: headers.count) }
        return (headers, Array(body))
    }

    /// All capture-group-1 substrings for `pattern` in `text` (dotall, case-insensitive).
    private static func capturedGroups(_ pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern,
                                                   options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return []
        }
        let ns = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).compactMap { match in
            let range = match.range(at: 1)
            guard range.location != NSNotFound else { return nil }
            return ns.substring(with: range)
        }
    }

    /// Strip inner tags, decode common entities, collapse whitespace.
    private static func cleanCell(_ raw: String) -> String {
        var s = raw.replacingOccurrences(of: "<[^>]+>", with: "", options: [.regularExpression])
        s = decodeEntities(s)
        s = s.replacingOccurrences(of: "\\s+", with: " ", options: [.regularExpression])
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func decodeEntities(_ s: String) -> String {
        var r = s
        // &amp; is decoded last so e.g. "&amp;lt;" doesn't collapse to "<".
        let pairs: [(String, String)] = [
            ("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""),
            ("&#39;", "'"), ("&apos;", "'"), ("&nbsp;", " "), ("&amp;", "&"),
        ]
        for (entity, char) in pairs {
            r = r.replacingOccurrences(of: entity, with: char, options: [.caseInsensitive])
        }
        return r
    }

    private static func escapeHTML(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    // MARK: - Rendering
    //
    // These are deliberately YAML-/TOML-*style* (not spec-strict): values and keys are
    // emitted raw — no quoting — for readability. Cells are already single-line (Markdown
    // rows are one line; HTML cells collapse whitespace), so raw emission stays well-formed.

    private static func render(headers: [String], rows: [[String]], format: Format) -> String {
        switch format {
        case .yaml: return renderYAML(headers: headers, rows: rows)
        case .toml: return renderTOML(headers: headers, rows: rows)
        }
    }

    /// YAML-style: one list item per row, `- header: value` then indented `header: value`.
    private static func renderYAML(headers: [String], rows: [[String]]) -> String {
        var out: [String] = []
        for row in rows {
            for (col, header) in headers.enumerated() {
                let value = col < row.count ? row[col] : ""
                let entry = value.isEmpty ? "\(header):" : "\(header): \(value)"
                out.append(col == 0 ? "- \(entry)" : "  \(entry)")
            }
        }
        return out.joined(separator: "\n")
    }

    /// TOML-style: one `header = value` block per row, blank-line separated (no `[[rows]]`).
    private static func renderTOML(headers: [String], rows: [[String]]) -> String {
        var blocks: [String] = []
        for row in rows {
            var lines: [String] = []
            for (col, header) in headers.enumerated() {
                let value = col < row.count ? row[col] : ""
                lines.append(value.isEmpty ? "\(header) =" : "\(header) = \(value)")
            }
            blocks.append(lines.joined(separator: "\n"))
        }
        return blocks.joined(separator: "\n\n")
    }
}
