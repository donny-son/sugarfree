import Foundation

#if canImport(AppKit)
import AppKit
#endif

/// Best-effort system-clipboard access for `--clipboard`.
///
/// macOS uses NSPasteboard directly. Other platforms shell out to whatever
/// standard clipboard tool is installed (Wayland, X11, or Windows), and report a
/// clear error if none is found. Only plain-string content is supported here —
/// the CLI's main job is the stdin→stdout filter; clipboard is a convenience.
enum Clipboard {
    struct UnsupportedError: Error, CustomStringConvertible {
        let description: String
    }

    static func read() throws -> String {
        #if canImport(AppKit)
        return NSPasteboard.general.string(forType: .string) ?? ""
        #else
        for (tool, args) in pasteCommands() where toolExists(tool) {
            return try run(tool, args)
        }
        throw UnsupportedError(description: clipboardHelp(verb: "read"))
        #endif
    }

    static func write(_ string: String) throws {
        #if canImport(AppKit)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(string, forType: .string)
        #else
        for (tool, args) in copyCommands() where toolExists(tool) {
            try run(tool, args, stdin: string)
            return
        }
        throw UnsupportedError(description: clipboardHelp(verb: "write"))
        #endif
    }

    // MARK: - Non-macOS helpers

    #if !canImport(AppKit)
    private static func pasteCommands() -> [(String, [String])] {
        [("wl-paste", ["--no-newline"]),
         ("xclip", ["-selection", "clipboard", "-o"]),
         ("xsel", ["--clipboard", "--output"]),
         ("powershell", ["-NoProfile", "-Command", "Get-Clipboard"])]
    }

    private static func copyCommands() -> [(String, [String])] {
        [("wl-copy", []),
         ("xclip", ["-selection", "clipboard"]),
         ("xsel", ["--clipboard", "--input"]),
         ("clip", [])]
    }

    private static func clipboardHelp(verb: String) -> String {
        "no clipboard tool found to \(verb) the clipboard — install one of "
            + "wl-clipboard, xclip, or xsel (Linux), or use the default stdin/stdout mode instead."
    }

    private static func toolExists(_ name: String) -> Bool {
        let which = ProcessInfo.processInfo.environment["SystemRoot"] != nil ? "where" : "which"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [which, name]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    @discardableResult
    private static func run(_ tool: String, _ args: [String], stdin: String? = nil) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [tool] + args

        let outPipe = Pipe()
        process.standardOutput = outPipe
        var inPipe: Pipe?
        if stdin != nil {
            inPipe = Pipe()
            process.standardInput = inPipe
        }

        try process.run()
        if let stdin, let inPipe {
            inPipe.fileHandleForWriting.write(Data(stdin.utf8))
            inPipe.fileHandleForWriting.closeFile()
        }
        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(decoding: data, as: UTF8.self)
    }
    #endif
}
