import Foundation

// Stripping rules — one rule set, gated per sugar. These are pure string
// transforms (no AppKit), so they compile and run on every platform Swift
// supports and stay the single source of truth shared by the app and the CLI.
// RTF lives in StripRTF.swift because it needs AppKit.

/// HTML: unwrap tags + drop inline-style declarations, per sugar. Best-effort regex.
/// Returns the rewritten HTML and the set of sugars actually removed.
public func stripHTML(_ html: String, sugars: Set<Sugar>) -> (String, Set<Sugar>) {
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
public func stripPlainText(_ text: String, sugars: Set<Sugar>) -> (String, Set<Sugar>) {
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
