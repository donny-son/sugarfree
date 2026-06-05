import Foundation

/// A dash the app can normalize to a plain spaced hyphen (`" - "`). Unlike `Sugar`
/// (which removes an emphasis *marker* and keeps the inner text), a dash *is* content —
/// so this is lossy substitution, not stripping. The user toggles each kind; it stays
/// off by default and lives in its own "Punctuation" dashboard section.
enum Punctuation: String, CaseIterable, Identifiable {
    case emDash
    case enDash

    var id: Self { self }

    var title: String {
        switch self {
        case .emDash: return "Em-dash"
        case .enDash: return "En-dash"
        }
    }

    /// Short hint shown beside the toggle (the input form that gets normalized).
    var example: String {
        switch self {
        case .emDash: return "wait—what"
        case .enDash: return "10–20"
        }
    }

    /// Longer description for the Settings rows.
    var detail: String {
        switch self {
        case .emDash:
            return "Replaces em-dashes (— and &mdash;) with a spaced hyphen, collapsing surrounding spaces."
        case .enDash:
            return "Replaces en-dashes (– and &ndash;) with a spaced hyphen, collapsing surrounding spaces."
        }
    }

    var symbolName: String {
        switch self {
        case .emDash: return "minus"
        case .enDash: return "minus"
        }
    }

    /// The literal dash character (decoded form found in plain text and RTF).
    fileprivate var character: String {
        switch self {
        case .emDash: return "\u{2014}"
        case .enDash: return "\u{2013}"
        }
    }

    /// HTML entity spellings for this dash (numeric + named).
    fileprivate var entities: [String] {
        switch self {
        case .emDash: return ["&mdash;", "&#8212;", "&#x2014;"]
        case .enDash: return ["&ndash;", "&#8211;", "&#x2013;"]
        }
    }

    /// Regex matching the literal dash with any surrounding ASCII spaces/tabs (not newlines,
    /// so line breaks survive). Used for plain text and RTF.
    fileprivate var textPattern: String {
        "[ \\t]*\(NSRegularExpression.escapedPattern(for: character))[ \\t]*"
    }

    /// Like `textPattern`, but also matches the HTML entity spellings.
    fileprivate var htmlPattern: String {
        let forms = ([character] + entities).map(NSRegularExpression.escapedPattern(for:))
        return "[ \\t]*(?:\(forms.joined(separator: "|")))[ \\t]*"
    }
}

/// Pure, Foundation-only dash normalization. Mirrors `TableConverter`'s shape so it can be
/// unit-tested without the AppKit-importing `PasteboardMonitor`.
enum DashNormalizer {
    /// What every matched dash (plus its hugging spaces) collapses to.
    static let replacement = " - "

    /// Normalize the enabled dash kinds in plain text. Returns the rewritten text and the
    /// set of kinds that actually changed something.
    static func normalizePlainText(_ text: String, kinds: Set<Punctuation>) -> (String, Set<Punctuation>) {
        apply(text, kinds: kinds, pattern: \.textPattern)
    }

    /// Normalize the enabled dash kinds in HTML, matching both the literal character and the
    /// entity spellings (`&mdash;` / `&#8212;` / `&#x2014;`, etc.).
    static func normalizeHTML(_ html: String, kinds: Set<Punctuation>) -> (String, Set<Punctuation>) {
        apply(html, kinds: kinds, pattern: \.htmlPattern)
    }

    /// Normalize the enabled dash kinds in place inside a mutable string — used for RTF, where
    /// the dash is a literal character in the attributed string's backing store (mutating via
    /// `mutableString` keeps attribute ranges consistent). Entities don't occur in decoded RTF,
    /// so only the literal-character pattern applies. Returns the kinds that changed something.
    @discardableResult
    static func normalizeMutableString(_ string: NSMutableString, kinds: Set<Punctuation>) -> Set<Punctuation> {
        var changed: Set<Punctuation> = []
        for kind in Punctuation.allCases where kinds.contains(kind) {
            // Recompute the range each pass — replacements change the string's length.
            let count = string.replaceOccurrences(
                of: kind.textPattern,
                with: replacement,
                options: [.regularExpression, .caseInsensitive],
                range: NSRange(location: 0, length: string.length))
            if count > 0 { changed.insert(kind) }
        }
        return changed
    }

    private static func apply(_ input: String,
                              kinds: Set<Punctuation>,
                              pattern: KeyPath<Punctuation, String>) -> (String, Set<Punctuation>) {
        var result = input
        var changed: Set<Punctuation> = []
        // Iterate allCases (stable order) so output is deterministic regardless of Set order.
        for kind in Punctuation.allCases where kinds.contains(kind) {
            let before = result
            result = result.replacingOccurrences(
                of: kind[keyPath: pattern],
                with: replacement,
                options: [.regularExpression, .caseInsensitive])
            if result != before { changed.insert(kind) }
        }
        return (result, changed)
    }
}
