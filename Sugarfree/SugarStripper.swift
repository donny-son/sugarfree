import Foundation

/// A kind of formatting "sugar" the app can strip. The user toggles each one;
/// every enabled sugar is removed across whichever clipboard representations
/// carry it (RTF traits/attributes, HTML tags/styles, markdown markers).
///
/// Lives here (Foundation-only) rather than in `PasteboardMonitor` so the same
/// type and rule set are shared by the menu-bar app and the `sugarfree` CLI.
enum Sugar: String, CaseIterable, Identifiable {
    case bold
    case italic
    case underline
    case strikethrough
    case heading

    var id: Self { self }

    /// Bold + italic are the everyday annoyances; underline/strikethrough often carry
    /// meaning, so they stay off until the user opts in. Shared by the app's default
    /// preferences and the CLI's default strip set so the two stay in parity.
    static let defaults: Set<Sugar> = [.bold, .italic]

    var title: String {
        switch self {
        case .bold: return "Bold"
        case .italic: return "Italic"
        case .underline: return "Underline"
        case .strikethrough: return "Strikethrough"
        case .heading: return "Headers"
        }
    }

    /// Short syntax hint shown beside the toggle.
    var example: String {
        switch self {
        case .bold: return "**bold**"
        case .italic: return "*italic*"
        case .underline: return "<u>under</u>"
        case .strikethrough: return "~~strike~~"
        case .heading: return "# Heading"
        }
    }

    /// Longer description for the Settings rows.
    var detail: String {
        switch self {
        case .bold:
            return "Removes bold — RTF traits, <strong>/<b>, font-weight, and ** __ markers."
        case .italic:
            return "Removes italic — RTF traits, <em>/<i>, font-style, and * _ markers."
        case .underline:
            return "Removes underline — RTF underline, <u>, and text-decoration."
        case .strikethrough:
            return "Removes strikethrough — RTF, <s>/<del>, text-decoration, and ~~ markers."
        case .heading:
            return "Removes heading markers — leading #..###### at the start of a line, and <h1>–<h6> tags. Keeps the text."
        }
    }

    var symbolName: String {
        switch self {
        case .bold: return "bold"
        case .italic: return "italic"
        case .underline: return "underline"
        case .strikethrough: return "strikethrough"
        case .heading: return "number"
        }
    }
}

/// The pure (AppKit-free) sugar strippers for the text-bearing clipboard
/// representations — HTML markup and plain-text/markdown markers. One typed rule
/// set, gated per sugar, shared by `PasteboardMonitor` (which adds RTF on top via
/// AppKit) and the `sugarfree` CLI (which pipes text through these directly).
///
/// Best-effort regex (no DOM parse), matching the documented caveats in the README.
enum SugarStripper {

    /// HTML: unwrap tags + drop inline-style declarations, per sugar. Best-effort regex.
    /// Returns the rewritten string and the set of sugars actually removed.
    static func stripHTML(_ html: String, sugars: Set<Sugar>) -> (String, Set<Sugar>) {
        var result = html
        var removed: Set<Sugar> = []

        func strip(_ sugar: Sugar, tags: [String], styles: [String]) {
            guard sugars.contains(sugar) else { return }
            let before = result
            for pattern in tags {
                result = result.replacingOccurrences(of: pattern, with: "$1",
                                                      options: [.regularExpression, .caseInsensitive])
            }
            for pattern in styles {
                result = result.replacingOccurrences(of: pattern, with: "",
                                                      options: [.regularExpression, .caseInsensitive])
            }
            if result != before { removed.insert(sugar) }
        }

        strip(.bold,
              tags: ["<strong[^>]*>(.*?)</strong>", "<b[^>]*>(.*?)</b>"],
              styles: ["font-weight\\s*:\\s*[^;\"']+;?"])
        strip(.italic,
              tags: ["<em[^>]*>(.*?)</em>", "<i[^>]*>(.*?)</i>"],
              styles: ["font-style\\s*:\\s*italic\\s*;?"])
        strip(.underline,
              tags: ["<u[^>]*>(.*?)</u>"],
              styles: ["text-decoration(?:-line)?\\s*:\\s*underline\\s*;?"])
        strip(.strikethrough,
              tags: ["<s[^>]*>(.*?)</s>", "<del[^>]*>(.*?)</del>", "<strike[^>]*>(.*?)</strike>"],
              styles: ["text-decoration(?:-line)?\\s*:\\s*line-through\\s*;?"])

        // Headings: unwrap <h1>–<h6> to their inner text. Uses a backreference so the close
        // tag matches the open level, so it can't fold through the generic `strip` helper
        // (which always replaces with $1).
        if sugars.contains(.heading) {
            let before = result
            result = result.replacingOccurrences(
                of: "<h([1-6])[^>]*>(.*?)</h\\1>",
                with: "$2",
                options: [.regularExpression, .caseInsensitive])
            if result != before { removed.insert(.heading) }
        }

        return (result, removed)
    }

    /// Plain text / markdown markers. Underline has no markdown form, so it's skipped here.
    /// Bold runs before italic so `**` isn't half-consumed by the single-`*` rule.
    static func stripPlainText(_ text: String, sugars: Set<Sugar>) -> (String, Set<Sugar>) {
        var result = text
        var removed: Set<Sugar> = []

        func strip(_ sugar: Sugar, _ patterns: [String]) {
            guard sugars.contains(sugar) else { return }
            let before = result
            for pattern in patterns {
                result = result.replacingOccurrences(of: pattern, with: "$1", options: .regularExpression)
            }
            if result != before { removed.insert(sugar) }
        }

        // Headings: leading #..###### at the start of a line (ATX). Anchored to line start
        // (multiline `^`) and requires whitespace after the hashes, so a `#` used as a
        // regular character mid-line — or `#tag` with no space — is left untouched. An
        // optional trailing closing run of `#` is dropped too. Keeps the heading text.
        strip(.heading, ["(?m)^[ \\t]{0,3}#{1,6}[ \\t]+(.*?)(?:[ \\t]+#+)?[ \\t]*$"])
        strip(.strikethrough, ["~~(.+?)~~"])
        strip(.bold, ["\\*\\*(.+?)\\*\\*", "__(.+?)__"])
        // Italic: single * (not part of **), and _ only at non-alphanumeric boundaries so
        // snake_case identifiers survive.
        strip(.italic, ["(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)",
                        "(?<![A-Za-z0-9])_(.+?)_(?![A-Za-z0-9])"])

        return (result, removed)
    }
}
