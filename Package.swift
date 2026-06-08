// swift-tools-version:5.9
import PackageDescription

// SwiftPM package for the cross-platform pieces of Sugarfree.
//
// `SugarCore` is the single source of truth for the formatting-stripping and
// table-transform logic. Both the macOS app (via XcodeGen, see project.yml) and
// the `sugarfree` CLI consume it, so the rules never drift between platforms.
//
// The CLI builds and runs anywhere Swift does (macOS, Linux, Windows). RTF
// stripping needs AppKit, so it is gated `#if canImport(AppKit)` inside SugarCore
// and is simply unavailable off macOS.
let package = Package(
    name: "sugarfree",
    products: [
        .library(name: "SugarCore", targets: ["SugarCore"]),
        .executable(name: "sugarfree", targets: ["sugarfree"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .target(name: "SugarCore"),
        .executableTarget(
            name: "sugarfree",
            dependencies: [
                "SugarCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(name: "SugarCoreTests", dependencies: ["SugarCore"]),
    ]
)
