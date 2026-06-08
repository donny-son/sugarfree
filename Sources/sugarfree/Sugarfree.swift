import ArgumentParser
import Foundation
import SugarCore

/// The input representation to treat the content as.
enum InputFormat: String, CaseIterable, ExpressibleByArgument {
    case auto
    case text
    case html
    case rtf
}

/// Table list style flag. A local mirror of `TransformOutputFormat` so we don't add a
/// retroactive `ExpressibleByArgument` conformance to a type from another module.
enum TableStyle: String, CaseIterable, ExpressibleByArgument {
    case yaml
    case toml

    var output: TransformOutputFormat {
        switch self {
        case .yaml: return .yaml
        case .toml: return .toml
        }
    }
}

@main
struct Sugarfree: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sugarfree",
        abstract: "Strip formatting sugar from text, HTML, or RTF — and optionally convert tables to lists.",
        discussion: """
        Reads from a FILE or stdin, strips the selected sugars, and writes the result
        to stdout (a Unix filter). Bold and italic are stripped by default; use --all,
        --none, or the per-sugar flags to change that.

        Examples:
          pbpaste | sugarfree                 strip bold+italic from clipboard text
          sugarfree --all notes.md            strip every sugar from a file
          sugarfree --none --tables in.md     leave emphasis, convert tables to YAML
          cat page.html | sugarfree --html    strip from HTML
          sugarfree --clipboard --all         clean the system clipboard in place
        """,
        version: "1.4.0"
    )

    @Argument(help: "Input file. Omit to read from stdin (unless --clipboard).")
    var file: String?

    @Flag(inversion: .prefixedNo, help: "Strip bold. Default: on.")
    var bold: Bool?

    @Flag(inversion: .prefixedNo, help: "Strip italic. Default: on.")
    var italic: Bool?

    @Flag(inversion: .prefixedNo, help: "Strip underline (HTML/RTF only).")
    var underline: Bool?

    @Flag(inversion: .prefixedNo, help: "Strip strikethrough.")
    var strikethrough: Bool?

    @Flag(inversion: .prefixedNo, help: "Strip headers.")
    var headers: Bool?

    @Flag(help: "Strip every sugar (overrides the bold+italic default).")
    var all = false

    @Flag(help: "Strip no sugars — useful with --tables for transform-only runs.")
    var none = false

    @Option(help: "Input representation: auto, text, html, or rtf.")
    var format: InputFormat = .auto

    @Flag(help: "Convert Markdown and HTML tables into list items.")
    var tables = false

    @Option(name: .customLong("table-format"), help: "Table list style: yaml or toml.")
    var tableFormat: TableStyle = .yaml

    @Flag(help: "Read input from and write the result back to the system clipboard.")
    var clipboard = false

    @Flag(help: "Don't write output; exit 3 if the content would change, 0 otherwise.")
    var check = false

    func validate() throws {
        if all && none {
            throw ValidationError("--all and --none are mutually exclusive.")
        }
        if clipboard && file != nil {
            throw ValidationError("Pass either a FILE or --clipboard, not both.")
        }
    }

    func run() throws {
        let sugars = resolvedSugars()
        let tableFmt = tableFormat.output.converterFormat

        // --- read raw input ---
        let rawData = try readInput()
        let resolvedFormat = resolveFormat(rawData)

        if resolvedFormat == .rtf {
            try runRTF(rawData, sugars: sugars)
            return
        }

        let input = String(decoding: rawData, as: UTF8.self)
        var output = input

        switch resolvedFormat {
        case .html:
            output = stripHTML(output, sugars: sugars).0
            if tables {
                output = TableConverter.convertHTMLTables(in: output, format: tableFmt).0
            }
        default: // .text (and .auto already narrowed away from html/rtf)
            output = stripPlainText(output, sugars: sugars).0
            if tables {
                output = TableConverter.convertMarkdownTables(in: output, format: tableFmt).0
            }
        }

        let changed = output != input
        if check {
            throw ExitCode(changed ? 3 : 0)
        }
        try writeOutput(output)
    }

    // MARK: - Sugar selection

    private func resolvedSugars() -> Set<Sugar> {
        var sugars: Set<Sugar>
        if all {
            sugars = Set(Sugar.allCases)
        } else if none {
            sugars = []
        } else {
            sugars = [.bold, .italic]
        }

        func apply(_ sugar: Sugar, _ value: Bool?) {
            guard let value else { return }
            if value { sugars.insert(sugar) } else { sugars.remove(sugar) }
        }
        apply(.bold, bold)
        apply(.italic, italic)
        apply(.underline, underline)
        apply(.strikethrough, strikethrough)
        apply(.heading, headers)
        return sugars
    }

    // MARK: - Format resolution

    private func resolveFormat(_ data: Data) -> InputFormat {
        guard format == .auto else { return format }
        // RTF files start with the "{\rtf" signature.
        if data.starts(with: Array("{\\rtf".utf8)) { return .rtf }
        let text = String(decoding: data.prefix(4096), as: UTF8.self)
        let looksHTML = text.range(of: "<[a-zA-Z!/][^>]*>", options: .regularExpression) != nil
        return looksHTML ? .html : .text
    }

    // MARK: - RTF (macOS only)

    private func runRTF(_ data: Data, sugars: Set<Sugar>) throws {
        #if canImport(AppKit)
        let (stripped, removed) = stripRTF(data, sugars: sugars)
        let outData = (stripped != nil && !removed.isEmpty) ? stripped! : data
        let changed = !removed.isEmpty
        if check {
            throw ExitCode(changed ? 3 : 0)
        }
        if clipboard {
            // Clipboard mode only carries strings here; surface the stripped text.
            throw ValidationError("RTF + --clipboard isn't supported; write RTF to stdout/a file instead.")
        }
        FileHandle.standardOutput.write(outData)
        #else
        throw ValidationError("RTF stripping is only available on macOS.")
        #endif
    }

    // MARK: - I/O

    private func readInput() throws -> Data {
        if clipboard {
            return Data(try Clipboard.read().utf8)
        }
        if let file {
            return try Data(contentsOf: URL(fileURLWithPath: file))
        }
        return FileHandle.standardInput.readDataToEndOfFile()
    }

    private func writeOutput(_ string: String) throws {
        if clipboard {
            try Clipboard.write(string)
        } else {
            FileHandle.standardOutput.write(Data(string.utf8))
        }
    }
}
