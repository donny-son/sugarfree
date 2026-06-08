import Foundation

#if canImport(AppKit)
import AppKit

// RTF stripping relies on NSAttributedString's RTF (de)serialization and NSFont
// trait math, which live in AppKit — macOS only. On Linux/Windows this whole file
// compiles out, so callers there should fall back to the HTML/plain-text reps.

/// RTF: bold/italic are symbolic font traits; underline/strikethrough are their own
/// attributes. Returns the rewritten data and the set of sugars actually removed.
public func stripRTF(_ data: Data, sugars: Set<Sugar>) -> (Data?, Set<Sugar>) {
    guard let attr = NSMutableAttributedString(rtf: data, documentAttributes: nil) else {
        return (nil, [])
    }

    let full = NSRange(location: 0, length: attr.length)
    var removed: Set<Sugar> = []

    if sugars.contains(.bold) || sugars.contains(.italic) {
        attr.enumerateAttribute(.font, in: full, options: []) { value, range, _ in
            guard let font = value as? NSFont else { return }
            let descriptor = font.fontDescriptor
            var traits = descriptor.symbolicTraits
            var changed = false

            if sugars.contains(.bold), traits.contains(.bold) {
                traits.remove(.bold)
                removed.insert(.bold)
                changed = true
            }
            if sugars.contains(.italic), traits.contains(.italic) {
                traits.remove(.italic)
                removed.insert(.italic)
                changed = true
            }

            guard changed else { return }
            let updatedDescriptor = descriptor.withSymbolicTraits(traits)
            let updatedFont = NSFont(descriptor: updatedDescriptor, size: font.pointSize) ?? font
            attr.addAttribute(.font, value: updatedFont, range: range)
        }
    }

    if sugars.contains(.underline) {
        removeAttributeIfPresent(.underlineStyle, in: attr, range: full) { removed.insert(.underline) }
    }
    if sugars.contains(.strikethrough) {
        removeAttributeIfPresent(.strikethroughStyle, in: attr, range: full) { removed.insert(.strikethrough) }
    }

    guard !removed.isEmpty else { return (nil, []) }
    return (attr.rtf(from: full, documentAttributes: [:]), removed)
}

/// Collect non-zero ranges first, then clear — avoids mutating the attribute mid-enumeration.
private func removeAttributeIfPresent(_ name: NSAttributedString.Key,
                                      in attr: NSMutableAttributedString,
                                      range: NSRange,
                                      onRemoval: () -> Void) {
    var ranges: [NSRange] = []
    attr.enumerateAttribute(name, in: range, options: []) { value, range, _ in
        if let style = (value as? NSNumber)?.intValue, style != 0 {
            ranges.append(range)
        }
    }
    guard !ranges.isEmpty else { return }
    ranges.forEach { attr.removeAttribute(name, range: $0) }
    onRemoval()
}
#endif
