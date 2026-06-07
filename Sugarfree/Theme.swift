import AppKit
import SwiftUI

// MARK: - Surface palette (calm base)
//
// `Surface` is the calm base layer: line-art mark on warm paper, hard 1px borders,
// a hard offset shadow, zero gloss. It owns surfaces + text only — the brand
// accent lives in `Cotton` below. Colors are appearance-adaptive so the popover
// respects dark mode while keeping the warm paper character.

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

enum Surface {
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

    // Idle / attention accent (amber). The active "cleaning" state uses the Cotton accent.
    static let idle = Color(lightHex: 0xB0721A, darkHex: 0xE3B341)
}

// MARK: - Cotton accent
//
// The brand accent for "sugarfree": a cotton-candy gradient. Body surfaces stay
// calm paper for legibility — Cotton appears ONLY on the wordmark, ON toggles,
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
            .fill(Surface.markTile)
            .frame(width: size, height: size)
            .overlay(
                Image("LollipopOff")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.2)
                    .foregroundStyle(Surface.markGlyph)
            )
    }
}

// MARK: - Surface sheet (hard offset shadow)

struct SurfaceSheet: ViewModifier {
    var padding: CGFloat = 14
    var corner: CGFloat = 14
    var offset: CGFloat = 4

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Surface.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Surface.border, lineWidth: 1)
            )
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Surface.border)
                    .offset(x: offset, y: offset)
            )
    }
}

extension View {
    func surfaceSheet(padding: CGFloat = 14, corner: CGFloat = 14, offset: CGFloat = 4) -> some View {
        modifier(SurfaceSheet(padding: padding, corner: corner, offset: offset))
    }
}

/// A flat hairline-bordered block used to group rows inside a sheet.
struct SurfaceBlock: ViewModifier {
    var padding: CGFloat = 12
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Surface.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func surfaceBlock(padding: CGFloat = 12) -> some View {
        modifier(SurfaceBlock(padding: padding))
    }
}

struct SurfaceRule: View {
    var body: some View {
        Rectangle()
            .fill(Surface.hairline)
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
            .foregroundStyle(Surface.secondary)
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

// MARK: - Keycap (shortcut hint)

/// A single keyboard keycap — paper surface, hard 1px ink border, and the brand's hard
/// offset shadow (the same language as `SurfaceSheet`). Renders one glyph (`⌘`, `⇧`, `P`…)
/// in mono at a fixed height so a row of caps lines up cleanly.
struct Keycap: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(Surface.text)
            .frame(minWidth: 12)
            .frame(height: 20)
            .padding(.horizontal, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Surface.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Surface.border, lineWidth: 1)
            )
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Surface.border)
                    .offset(x: 1.5, y: 1.5)
            )
    }
}

/// A shortcut hint: a run of `Keycap`s for the key combo, then a plain-language action label.
struct ShortcutHint: View {
    let keys: [String]
    let action: String

    var body: some View {
        HStack(spacing: 7) {
            HStack(spacing: 4) {
                ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                    Keycap(label: key)
                }
            }

            Text(action)
                .font(.system(size: 12))
                .foregroundStyle(Surface.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(keys.joined(separator: " ")) \(action)")
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
        case .paused: return Surface.hairline
        case .idle: return Surface.idle.opacity(0.16)
        }
    }

    private var textColor: Color {
        switch state {
        case .active: return Cotton.ink
        case .paused: return Surface.secondary
        case .idle: return Surface.idle
        }
    }
}
