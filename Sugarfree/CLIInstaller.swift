import Foundation

/// Installs the bundled `sugarfree` CLI onto the user's PATH.
///
/// The DMG build embeds a universal `sugarfree` binary inside the app at
/// `Contents/Resources/sugarfree` (see release.sh). On first launch we symlink it
/// into `/usr/local/bin` so `sugarfree` works from any terminal. We try a direct
/// symlink first (no prompt) and only escalate to an admin prompt if that path
/// isn't writable. The attempt runs once — tracked in UserDefaults — so we never
/// nag on every launch.
enum CLIInstaller {
    private static let didAttemptKey = "didAttemptCLIInstall"
    private static let linkPath = "/usr/local/bin/sugarfree"
    private static let binDir = "/usr/local/bin"

    enum Result {
        case alreadyLinked
        case linked
        case noBundledCLI
        case skipped
        case failed(String)
    }

    /// Run once per machine. Safe to call on every launch.
    static func installIfNeeded(force: Bool = false) {
        guard force || !UserDefaults.standard.bool(forKey: didAttemptKey) else { return }

        // Locate the embedded CLI. Dev builds (xcodebuild Debug) won't have it.
        guard let cliURL = Bundle.main.url(forResource: "sugarfree", withExtension: nil) else {
            UserDefaults.standard.set(true, forKey: didAttemptKey)
            return
        }

        // Do the filesystem work off the main thread; an admin prompt may block.
        DispatchQueue.global(qos: .utility).async {
            let result = install(cliPath: cliURL.path)
            UserDefaults.standard.set(true, forKey: didAttemptKey)
            #if DEBUG
            print("CLIInstaller: \(result)")
            #endif
        }
    }

    private static func install(cliPath: String) -> Result {
        let fm = FileManager.default

        // Already pointing at this binary? Nothing to do.
        if let dest = try? fm.destinationOfSymbolicLink(atPath: linkPath), dest == cliPath {
            return .alreadyLinked
        }

        // Try a direct symlink (works when /usr/local/bin exists and is writable).
        if fm.isWritableFile(atPath: binDir) || createBinDirIfPossible() {
            do {
                if fm.fileExists(atPath: linkPath) || isSymlink(linkPath) {
                    try fm.removeItem(atPath: linkPath)
                }
                try fm.createSymbolicLink(atPath: linkPath, withDestinationPath: cliPath)
                return .linked
            } catch {
                // Fall through to the privileged path.
            }
        }

        return installWithAdmin(cliPath: cliPath)
    }

    private static func createBinDirIfPossible() -> Bool {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: binDir) else { return fm.isWritableFile(atPath: binDir) }
        return (try? fm.createDirectory(atPath: binDir, withIntermediateDirectories: true)) != nil
    }

    private static func isSymlink(_ path: String) -> Bool {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let type = attrs[.type] as? FileAttributeType else { return false }
        return type == .typeSymbolicLink
    }

    /// Last resort: ask for admin rights via AppleScript and create the symlink with sudo.
    private static func installWithAdmin(cliPath: String) -> Result {
        let escaped = cliPath.replacingOccurrences(of: "'", with: "'\\''")
        let shell = "mkdir -p \(binDir) && ln -sf '\(escaped)' \(linkPath)"
        let appleScript = "do shell script \"\(shellEscape(shell))\" with administrator privileges"

        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: appleScript) else {
            return .failed("could not build AppleScript")
        }
        script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            return .failed(errorInfo[NSAppleScript.errorMessage] as? String ?? "admin install failed")
        }
        return .linked
    }

    /// Escape a shell string for embedding inside an AppleScript double-quoted literal.
    private static func shellEscape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
