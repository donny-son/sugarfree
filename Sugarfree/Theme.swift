import AppKit
import SwiftUI

// MARK: - Surface palette (Liquid Glass base)
//
// The base layer is Apple-native translucent glass — not paper. Surfaces are
// `Material` (real-time blur + vibrancy), edges are thin specular highlights, and
// depth comes from soft float shadows, never a hard offset block. Text uses the
// system label colors so it stays legible and vibrant over whatever shows through
// the glass. The brand accent still lives in `Cotton` below.

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
    /// Primary text — system label, so it picks up vibrancy over glass.
    static let text = Color.primary
    static let secondary = Color.secondary
    static let tertiary = Color(nsColor: .tertiaryLabelColor)

    /// Hairline rules + control hairlines — the system separator (adaptive).
    static let hairline = Color(nsColor: .separatorColor)
    /// A faint inset fill for grouped glass cards (sits on top of the panel glass).
    static let groupFill = Color(lightHex: 0xFFFFFF, darkHex: 0xFFFFFF, alpha: 0.04)
    /// Thin specular edge highlight on glass panels/controls.
    static let glassEdge = Color(lightHex: 0xFFFFFF, darkHex: 0xFFFFFF, alpha: 0.22)

    /// Clean neutral background for real (non-popover) windows — the Apple settings
    /// gray, NOT warm paper. Onboarding paints this under its glass.
    static let windowBackground = Color(lightHex: 0xF5F5F7, darkHex: 0x1C1C1E)
    /// Legacy aliases kept for call sites that still reference them.
    static let desk = windowBackground
    static let surface = Color(lightHex: 0xFFFFFF, darkHex: 0x2A2A2D)
    static let border = Color(lightHex: 0x161616, darkHex: 0xF4F1EA)

    /// Brand-mark tile + glyph (inverted vs. surface for contrast in both modes).
    static let markTile = Color(lightHex: 0x161616, darkHex: 0xF2EFE8)
    static let markGlyph = Color(lightHex: 0xFAF8F3, darkHex: 0x161616)

    /// Idle / attention accent (amber). The active "cleaning" state uses the Cotton accent.
    static let idle = Color(lightHex: 0xB0721A, darkHex: 0xE3B341)
}

// MARK: - Cotton accent
//
// The brand accent for "sugarfree": a cotton-candy gradient. Glass surfaces stay
// neutral for legibility — Cotton appears ONLY on the wordmark, ON toggles, the
// primary button, the status pill, and (Aurora direction) a faint aura behind the
// header. Never wash a body surface with it.
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

    /// Dark outline stroked behind the wordmark so the candy gradient stays legible on the
    /// light aura / glass. A deep cotton-plum (not flat black) so it reads as on-brand.
    static let outline = Color(lightHex: 0x2A0A18, darkHex: 0x000000, alpha: 0.72)

    /// Discrete candy colors for celebratory bursts — the gradient stops as individual
    /// chips (menu-bar crush shards, popover confetti) and the Aurora bloom. A momentary,
    /// deliberate exception to "no gradient/brand color on a body surface".
    static let candy: [Color] = [g1, g2, g3]
}

// MARK: - Aurora background
//
// The approved "Aurora" glass direction: a faint cotton aura blooming from the top
// of the panel. Translucent so the glass underneath still reads — never a solid wash.
// Painted behind the dashboard content; the popover's own vibrant material is the glass.

struct AuroraBackground: View {
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [Cotton.candy[0].opacity(0.26), .clear]),
                center: .topLeading, startRadius: 0, endRadius: 240
            )
            RadialGradient(
                gradient: Gradient(colors: [Cotton.candy[2].opacity(0.18), .clear]),
                center: .topTrailing, startRadius: 0, endRadius: 240
            )
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Wordmark

/// The "sugarfree" wordmark: DynaPuff (rounded/candy) painted with the Cotton gradient,
/// over a thin dark outline so the candy stays legible against the light aura / glass.
struct Wordmark: View {
    var size: CGFloat = 22

    /// Outline thickness scales with the type size (~1px at 22pt, ~1.5px at 34pt).
    private var stroke: CGFloat { max(0.5, size * 0.05) }

    var body: some View {
        let glyphs = Text("sugarfree")
            .font(.custom("DynaPuff", size: size).weight(.semibold))
            .tracking(-0.2)

        ZStack {
            // Dark outline: the same glyphs in the outline color, offset around the
            // perimeter (8 directions) so they peek out from behind the gradient fill.
            ForEach(Wordmark.outlineUnits.indices, id: \.self) { index in
                let unit = Wordmark.outlineUnits[index]
                glyphs
                    .foregroundStyle(Cotton.outline)
                    .offset(x: unit.width * stroke, y: unit.height * stroke)
            }

            glyphs
                .foregroundStyle(Cotton.gradient)
        }
        .fixedSize()
    }

    /// Unit perimeter offsets (scaled by `stroke`): the 4 sides + 4 diagonals.
    private static let outlineUnits: [CGSize] = [
        CGSize(width: -1, height: 0), CGSize(width: 1, height: 0),
        CGSize(width: 0, height: -1), CGSize(width: 0, height: 1),
        CGSize(width: -1, height: -1), CGSize(width: 1, height: -1),
        CGSize(width: -1, height: 1), CGSize(width: 1, height: 1),
    ]
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
            .shadow(color: .black.opacity(0.18), radius: size * 0.22, y: size * 0.08)
    }
}

// MARK: - Glass panel (Material + specular edge + soft float shadow)

struct SurfaceSheet: ViewModifier {
    var padding: CGFloat = 14
    var corner: CGFloat = 18
    var offset: CGFloat = 0   // retained for API compatibility; glass uses a soft shadow

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Surface.glassEdge, lineWidth: 0.75)
            )
            .shadow(color: .black.opacity(0.20), radius: 22, y: 12)
    }
}

extension View {
    func surfaceSheet(padding: CGFloat = 14, corner: CGFloat = 18, offset: CGFloat = 0) -> some View {
        modifier(SurfaceSheet(padding: padding, corner: corner, offset: offset))
    }
}

/// An inset glass group used to cluster rows inside a panel — the native grouped-list card.
struct SurfaceBlock: ViewModifier {
    var padding: CGFloat = 12
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, padding)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Surface.groupFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Surface.hairline, lineWidth: 0.75)
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

// MARK: - Section label (native grouped-list header)

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.5)
            .textCase(.uppercase)
            .foregroundStyle(Surface.secondary)
    }
}

// MARK: - Primary button (cotton gradient + glass sheen)

struct CottonPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Cotton.buttonGradient)
            )
            .overlay(
                // Specular sheen across the top half — the "liquid" highlight.
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.30), .clear],
                            startPoint: .top, endPoint: .center
                        )
                    )
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(0.20), lineWidth: 0.5)
            )
            .shadow(color: Cotton.accent.opacity(0.40), radius: 10, y: 3)
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.35)
            .contentShape(Rectangle())
    }
}

// MARK: - Keycap (shortcut hint)

/// A single keyboard keycap rendered as a small glass capsule: a `Material` fill, a thin
/// specular edge, and a soft drop. Renders one glyph (`⌘`, `⇧`, `P`…) in mono at a fixed
/// height so a row of caps lines up cleanly.
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
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Surface.hairline, lineWidth: 0.75)
            )
            .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
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
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous).fill(fillColor)
            )
            .overlay(
                Capsule(style: .continuous).strokeBorder(strokeColor, lineWidth: 0.5)
            )
    }

    // Active = cotton; paused = neutral; idle = amber attention.
    private var fillColor: Color {
        switch state {
        case .active: return Cotton.tint
        case .paused: return Surface.hairline.opacity(0.6)
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

    private var strokeColor: Color {
        switch state {
        case .active: return Cotton.accent.opacity(0.35)
        case .paused: return .clear
        case .idle: return Surface.idle.opacity(0.30)
        }
    }
}
