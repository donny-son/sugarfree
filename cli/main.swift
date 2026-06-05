import Foundation

// sugarfree — a Unix filter that strips formatting "sugar" from text.
//
// Reads from stdin (or file arguments), strips the chosen sugars from the
// Markdown/plain-text (default) or HTML representation, optionally reshapes
// tables into list items, and writes the result to stdout. It reuses the exact
// same rule set as the menu-bar app (`SugarStripper` + `TableConverter`), so the
// pipe and the clipboard behave identically.
//
// Built for LLM pipelines, shell workflows, and Claude Code hooks, e.g.:
//
//     llm "explain X" | sugarfree
//     pbpaste | sugarfree --all | pbcopy
//     sugarfree --tables yaml < report.md

let version = "1.2.0"

let helpText = """
sugarfree — strip formatting sugar from text (stdin → stdout)

USAGE:
    sugarfree [OPTIONS] [FILE ...]

Reads from stdin when no FILE is given (use "-" for explicit stdin). With no
sugar flags it strips bold + italic — the same defaults as the menu-bar app.

SUGAR SELECTION:
    --all                  Strip every sugar (bold, italic, underline,
                           strikethrough, headers).
    --bold                 Strip bold (**x**, __x__, <strong>, <b>, font-weight).
    --italic               Strip italic (*x*, _x_, <em>, <i>, font-style).
    --underline            Strip underline (<u>, text-decoration; HTML only).
    --strikethrough        Strip strikethrough (~~x~~, <s>/<del>/<strike>).
    --headers              Strip ATX headers (# .. ###### …) and <h1>–<h6>.
    --strip <list>         Comma-separated set, e.g. --strip bold,headers.
    --no-<sugar>           Remove one sugar from the set (handy with --all),
                           e.g. --all --no-headers.

    Naming any --<sugar> / --strip flag replaces the bold+italic default with
    exactly the set you list. --no-<sugar> flags are applied last.

INPUT FORMAT:
    --html                 Treat input as HTML (default is Markdown/plain text).

TRANSFORMS (lossy, off by default):
    --tables <yaml|toml>   Convert Markdown/HTML tables into list items.

OTHER:
    -h, --help             Show this help.
    --version              Print the version.

EXAMPLES:
    llm "summarize" | sugarfree           # strip bold + italic
    pbpaste | sugarfree --all | pbcopy    # strip everything, back to clipboard
    sugarfree --strip headers,bold notes.md
    sugarfree --html < email.html
    sugarfree --tables toml < report.md
"""

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("sugarfree: \(message)\n".utf8))
    FileHandle.standardError.write(Data("Try 'sugarfree --help' for usage.\n".utf8))
    exit(2)
}

func parseTableFormat(_ value: String) -> TableConverter.Format {
    switch value.lowercased() {
    case "yaml", "yml": return .yaml
    case "toml": return .toml
    default: fail("unknown table format '\(value)' (expected yaml or toml)")
    }
}

func parseSugar(_ name: String) -> Sugar {
    switch name.lowercased() {
    case "bold": return .bold
    case "italic": return .italic
    case "underline": return .underline
    case "strikethrough", "strike": return .strikethrough
    case "heading", "headings", "header", "headers": return .heading
    default: fail("unknown sugar '\(name)' (expected bold, italic, underline, strikethrough, headers)")
    }
}

// MARK: - Argument parsing

var explicit = Set<Sugar>()      // sugars named via --<sugar> / --strip / --all
var explicitUsed = false         // did the user name any sugar explicitly?
var removals = Set<Sugar>()      // sugars subtracted via --no-<sugar>
var asHTML = false
var tableFormat: TableConverter.Format?
var files: [String] = []
var sawDoubleDash = false

var args = Array(CommandLine.arguments.dropFirst())
var index = 0
while index < args.count {
    let arg = args[index]
    index += 1

    if sawDoubleDash {
        files.append(arg)
        continue
    }

    switch arg {
    case "-h", "--help":
        print(helpText)
        exit(0)
    case "--version":
        print(version)
        exit(0)
    case "--":
        sawDoubleDash = true
    case "-":
        files.append(arg)
    case "--all":
        explicit.formUnion(Sugar.allCases)
        explicitUsed = true
    case "--bold", "--italic", "--underline", "--strikethrough", "--headers", "--heading":
        explicit.insert(parseSugar(String(arg.dropFirst(2))))
        explicitUsed = true
    case "--no-bold", "--no-italic", "--no-underline", "--no-strikethrough", "--no-headers", "--no-heading":
        removals.insert(parseSugar(String(arg.dropFirst(5))))
    case "--strip":
        guard index < args.count else { fail("--strip requires a comma-separated list") }
        let list = args[index]; index += 1
        for name in list.split(separator: ",") {
            explicit.insert(parseSugar(name.trimmingCharacters(in: .whitespaces)))
        }
        explicitUsed = true
    case "--html":
        asHTML = true
    case "--tables":
        guard index < args.count else { fail("--tables requires a format (yaml or toml)") }
        tableFormat = parseTableFormat(args[index]); index += 1
    default:
        if arg.hasPrefix("--strip=") {
            for name in arg.dropFirst("--strip=".count).split(separator: ",") {
                explicit.insert(parseSugar(name.trimmingCharacters(in: .whitespaces)))
            }
            explicitUsed = true
        } else if arg.hasPrefix("--tables=") {
            tableFormat = parseTableFormat(String(arg.dropFirst("--tables=".count)))
        } else if arg.hasPrefix("-") && arg != "-" {
            fail("unknown option '\(arg)'")
        } else {
            files.append(arg)
        }
    }
}

let sugars = (explicitUsed ? explicit : Sugar.defaults).subtracting(removals)

// MARK: - Processing

func process(_ text: String) -> String {
    var result: String
    if asHTML {
        result = SugarStripper.stripHTML(text, sugars: sugars).0
        if let tableFormat {
            result = TableConverter.convertHTMLTables(in: result, format: tableFormat).0
        }
    } else {
        result = SugarStripper.stripPlainText(text, sugars: sugars).0
        if let tableFormat {
            result = TableConverter.convertMarkdownTables(in: result, format: tableFormat).0
        }
    }
    return result
}

func readStdin() -> String {
    let data = FileHandle.standardInput.readDataToEndOfFile()
    return String(decoding: data, as: UTF8.self)
}

func readFile(_ path: String) -> String {
    if path == "-" { return readStdin() }
    guard let data = FileManager.default.contents(atPath: path) else {
        fail("cannot read file '\(path)'")
    }
    return String(decoding: data, as: UTF8.self)
}

let input: String
if files.isEmpty {
    input = readStdin()
} else {
    input = files.map(readFile).joined()
}

FileHandle.standardOutput.write(Data(process(input).utf8))
