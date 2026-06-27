import Foundation

/// A kind of formatting "sugar" the app can strip. The user toggles each one;
/// every enabled sugar is removed across whichever clipboard representations
/// carry it (RTF traits/attributes, HTML tags/styles, markdown markers).
public enum Sugar: String, CaseIterable, Identifiable, Sendable {
    case bold
    case italic
    case underline
    case strikethrough
    case heading
    case horizontalRule

    public var id: Self { self }

    public var title: String {
        switch self {
        case .bold: return "Bold"
        case .italic: return "Italic"
        case .underline: return "Underline"
        case .strikethrough: return "Strikethrough"
        case .heading: return "Headers"
        case .horizontalRule: return "Horizontal rules"
        }
    }

    /// Short syntax hint shown beside the toggle.
    public var example: String {
        switch self {
        case .bold: return "**bold**"
        case .italic: return "*italic*"
        case .underline: return "<u>under</u>"
        case .strikethrough: return "~~strike~~"
        case .heading: return "# Heading"
        case .horizontalRule: return "---"
        }
    }

    /// Longer description for the Settings rows.
    public var detail: String {
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
        case .horizontalRule:
            return "Removes horizontal rules — a line of --- *** ___ (thematic break) and <hr> tags."
        }
    }

    public var symbolName: String {
        switch self {
        case .bold: return "bold"
        case .italic: return "italic"
        case .underline: return "underline"
        case .strikethrough: return "strikethrough"
        case .heading: return "number"
        case .horizontalRule: return "minus"
        }
    }
}

/// A structural rewrite of clipboard content. Distinct from `Sugar` (which only
/// *removes* inline emphasis markers): a transform *reshapes* content into another
/// representation, which is lossy — so transforms default to off.
public enum Transform: String, CaseIterable, Identifiable, Sendable {
    case tablesToList

    public var id: Self { self }

    public var title: String {
        switch self {
        case .tablesToList: return "Tables → list"
        }
    }

    /// Short syntax hint shown beside the toggle.
    public var example: String {
        switch self {
        case .tablesToList: return "| a | b |"
        }
    }

    public var detail: String {
        switch self {
        case .tablesToList:
            return "Converts Markdown and HTML tables into YAML-style or TOML-style list items."
        }
    }

    public var symbolName: String {
        switch self {
        case .tablesToList: return "tablecells"
        }
    }
}

/// Output style for table → list transforms.
public enum TransformOutputFormat: String, CaseIterable, Identifiable, Sendable {
    case yaml
    case toml

    public var id: Self { self }

    public var title: String {
        switch self {
        case .yaml: return "YAML-style"
        case .toml: return "TOML-style"
        }
    }

    public var converterFormat: TableConverter.Format {
        switch self {
        case .yaml: return .yaml
        case .toml: return .toml
        }
    }
}
