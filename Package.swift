// swift-tools-version:5.9
import PackageDescription

// The `sugarfree` command-line filter. It builds independently of the menu-bar
// app's Xcode project (which is still generated from `project.yml` via XcodeGen),
// but reuses the exact same Foundation-only rule set — `SugarStripper` and
// `TableConverter` — so the pipe and the clipboard strip text identically.
//
//     swift build -c release
//     .build/release/sugarfree --help
//
// These sources import only Foundation (no AppKit), so the CLI builds on macOS
// and Linux alike.
let package = Package(
    name: "sugarfree",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "sugarfree",
            path: ".",
            sources: [
                "cli/main.swift",
                "Sugarfree/SugarStripper.swift",
                "Sugarfree/TableConverter.swift",
            ]
        )
    ]
)
