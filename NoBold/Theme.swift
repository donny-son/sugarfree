import AppKit
import SwiftUI

// MARK: - Ink palette
//
// The "Ink" identity: line-art mark on warm paper, hard 1px borders, a hard
// offset shadow, zero gloss. Monochrome with a single restrained status dot.
// Colors are appearance-adaptive so the popover still respects dark mode while
// keeping the paper/ink character.

extension NSColor {
    fileprivate convenience init(hex: UInt32) {
        self.init(
            srgbRed: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}

extension Color {
    /// Appearance-adaptive color built from explicit light/dark sRGB values.
    fileprivate init(lightHex: UInt32, darkHex: UInt32, alpha: CGFloat = 1.0) {
        let dynamic = NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(hex: isDark ? darkHex : lightHex).withAlphaComponent(alpha)
        }
        self.init(nsColor: dynamic)
    }
}

enum Ink {
    /// The window/desk behind the sheet — the darker of the two paper tones.
    static let desk = Color(lightHex: 0xECE9E1, darkHex: 0x121214)
    /// The sheet surface — the lighter paper tone.
    static let surface = Color(lightHex: 0xFAF8F3, darkHex: 0x1D1D1F)
    /// Primary ink.
    static let text = Color(lightHex: 0x161616, darkHex: 0xF4F1EA)
    static let secondary = Color(lightHex: 0x6A665D, darkHex: 0xA7A39A)
    static let tertiary = Color(lightHex: 0x8F8A7E, darkHex: 0x76726A)
    /// Hard borders + the offset shadow block.
    static let border = Color(lightHex: 0x161616, darkHex: 0xF4F1EA)
    /// Hairline rules between sections.
    static let hairline = Color(lightHex: 0x161616, darkHex: 0xF4F1EA, alpha: 0.12)
    /// Brand-mark tile + glyph (inverted vs. surface for contrast in both modes).
    static let markTile = Color(lightHex: 0x161616, darkHex: 0xF4F1EA)
    static let markGlyph = Color(lightHex: 0xFAF8F3, darkHex: 0x161616)

    // Restrained status accents (the only non-monochrome ink).
    static let active = Color(lightHex: 0x2E7D32, darkHex: 0x6FCF7F)
    static let idle = Color(lightHex: 0xB0721A, darkHex: 0xE3B341)
}

// MARK: - Brand mark

/// The stars-off logo on a solid ink tile — the app's primary brand lockup.
struct BrandMark: View {
    var size: CGFloat = 26
    var corner: CGFloat { size * 0.3 }

    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(Ink.markTile)
            .frame(width: size, height: size)
            .overlay(
                Image("StarsOff")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.2)
                    .foregroundStyle(Ink.markGlyph)
            )
    }
}

// MARK: - Ink sheet (hard offset shadow)

struct InkSheet: ViewModifier {
    var padding: CGFloat = 14
    var corner: CGFloat = 14
    var offset: CGFloat = 4

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Ink.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Ink.border, lineWidth: 1)
            )
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Ink.border)
                    .offset(x: offset, y: offset)
            )
    }
}

extension View {
    func inkSheet(padding: CGFloat = 14, corner: CGFloat = 14, offset: CGFloat = 4) -> some View {
        modifier(InkSheet(padding: padding, corner: corner, offset: offset))
    }
}

/// A flat hairline-bordered block used to group rows inside a sheet.
struct InkBlock: ViewModifier {
    var padding: CGFloat = 12
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Ink.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func inkBlock(padding: CGFloat = 12) -> some View {
        modifier(InkBlock(padding: padding))
    }
}

struct InkRule: View {
    var body: some View {
        Rectangle()
            .fill(Ink.hairline)
            .frame(height: 1)
    }
}

// MARK: - Section label

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(Ink.secondary)
    }
}

// MARK: - Primary button (filled ink)

struct InkPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(Ink.markGlyph)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Ink.markTile)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.35)
            .contentShape(Rectangle())
    }
}

// MARK: - Status pill

struct StatusPill: View {
    let state: MonitorInterfaceState

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)
            Text(state.title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(0.6)
                .foregroundStyle(Ink.text)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Ink.border, lineWidth: 1)
        )
    }

    private var dotColor: Color {
        switch state {
        case .active: return Ink.active
        case .paused: return Ink.tertiary
        case .idle: return Ink.idle
        }
    }
}
