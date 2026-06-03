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

// MARK: - Cotton accent
//
// The brand accent for "sugarfree": a cotton-candy gradient. Surfaces stay Ink
// (paper/ink) for legibility — Cotton appears ONLY on the wordmark, ON toggles,
// the primary button, and the status pill. Never wash a body surface with it.
// (The menubar glyph is a template image / system tint — always monochrome.)

enum Cotton {
    // Gradient stops (appearance-adaptive so the candy still reads in dark mode).
    private static let g1 = Color(lightHex: 0xFF6FB5, darkHex: 0xFF8AC4)
    private static let g2 = Color(lightHex: 0xFF9A6B, darkHex: 0xFFB07A)
    private static let g3 = Color(lightHex: 0xFFC857, darkHex: 0xFFD879)
    // Deeper anchors so white text reads on the button fill.
    private static let btn1 = Color(lightHex: 0xF0469B, darkHex: 0xFF5FAE)
    private static let btn2 = Color(lightHex: 0xFF7A4D, darkHex: 0xFF8A5B)

    /// Brand gradient — wordmark, app-icon mark, ON toggle.
    static var gradient: LinearGradient {
        LinearGradient(gradient: Gradient(colors: [g1, g2, g3]),
                       startPoint: .leading, endPoint: .trailing)
    }
    /// Deeper gradient for the primary button (white text reads on it).
    static var buttonGradient: LinearGradient {
        LinearGradient(gradient: Gradient(colors: [btn1, btn2]),
                       startPoint: .leading, endPoint: .trailing)
    }
    /// Solid accent for control tints (switch on-color) — gradients aren't valid `.tint`.
    static let accent = Color(lightHex: 0xF0469B, darkHex: 0xFF8AC4)
    /// Low-alpha fill behind the active status pill.
    static let tint = Color(lightHex: 0xFF6FB5, darkHex: 0xFF8AC4, alpha: 0.16)
    /// Deep-pink text on a cotton tint.
    static let ink = Color(lightHex: 0xC8327E, darkHex: 0xFF9ECB)
}

// MARK: - Wordmark

/// The "sugarfree" wordmark: DynaPuff (rounded/candy) painted with the Cotton gradient.
struct Wordmark: View {
    var size: CGFloat = 22

    var body: some View {
        Text("sugarfree")
            .font(.custom("DynaPuff", size: size).weight(.semibold))
            .tracking(-0.2)
            .foregroundStyle(Cotton.gradient)
            .fixedSize()
    }
}

// MARK: - Brand mark

/// The lollipop-off logo on a solid ink tile — the app's primary brand lockup.
struct BrandMark: View {
    var size: CGFloat = 26
    var corner: CGFloat { size * 0.3 }

    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(Ink.markTile)
            .frame(width: size, height: size)
            .overlay(
                Image("LollipopOff")
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

// MARK: - Primary button (cotton gradient)

struct CottonPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Cotton.buttonGradient)
            )
            .shadow(color: Cotton.accent.opacity(0.35), radius: 8, y: 2)
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.35)
            .contentShape(Rectangle())
    }
}

// MARK: - Status pill

struct StatusPill: View {
    let state: MonitorInterfaceState

    var body: some View {
        Text(state.title.uppercased())
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(0.6)
            .foregroundStyle(textColor)
            .padding(.horizontal, 9)
            .padding(.vertical, 3.5)
            .background(
                Capsule(style: .continuous).fill(fillColor)
            )
    }

    // Active = cotton; paused = neutral ink; idle = amber attention.
    private var fillColor: Color {
        switch state {
        case .active: return Cotton.tint
        case .paused: return Ink.hairline
        case .idle: return Ink.idle.opacity(0.16)
        }
    }

    private var textColor: Color {
        switch state {
        case .active: return Cotton.ink
        case .paused: return Ink.secondary
        case .idle: return Ink.idle
        }
    }
}
