import AppKit
import SwiftUI

struct MenuBarDashboard: View {
    @ObservedObject var monitor: PasteboardMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            brandRow
            statusSection
            SurfaceRule()
            controlSection
            SurfaceRule()
            formatsSection
            SurfaceRule()
            transformsSection
            SurfaceRule()
            footerRow
        }
        .surfaceSheet(padding: 16)
        .padding(14)
        .frame(width: 320)
        .background(Surface.desk)
    }

    private var brandRow: some View {
        HStack(spacing: 10) {
            Wordmark(size: 22)

            Spacer()

            StatusPill(state: monitor.interfaceState)
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monitor.statusHeadline)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Surface.text)

            Text(monitor.statusDetail)
                .font(.system(size: 11.5))
                .foregroundStyle(Surface.secondary)
                .fixedSize(horizontal: false, vertical: true)

            CleanedMetricTile(monitor: monitor)
                .padding(.top, 2)

            if let lastEvent = monitor.lastEvent {
                HStack(spacing: 4) {
                    Text(lastEvent.detail)
                    Text("·")
                    Text(lastEvent.timestamp, style: .relative)
                }
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(Surface.tertiary)
            }
        }
    }

    private var controlSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Automatic cleanup", isOn: $monitor.isEnabled)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Surface.text)
                .toggleStyle(.switch)
                .tint(Cotton.accent)

            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "Check interval")

                Picker("Check interval", selection: $monitor.pollingInterval) {
                    ForEach(PasteboardMonitor.allowedPollingIntervals, id: \.self) { interval in
                        Text(intervalLabel(for: interval)).tag(interval)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .tint(Cotton.accent)
            }

            Button {
                monitor.cleanClipboardManually()
            } label: {
                Text("Clean Now")
            }
            .buttonStyle(CottonPrimaryButtonStyle())
            .disabled(!monitor.hasWork)

            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "Shortcuts")

                ShortcutHint(keys: ["⌘", "⇧", "P"], action: "toggle cleanup")
                ShortcutHint(keys: ["⌘", "⇧", "K"], action: "clean now")
            }
            .padding(.top, 2)
        }
    }

    private var formatsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Sugars to strip")

            ForEach(Sugar.allCases) { sugar in
                SugarToggleRow(
                    sugar: sugar,
                    isEnabled: binding(for: sugar)
                )
            }
        }
    }

    private var transformsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Transforms")

            ForEach(Transform.allCases) { transform in
                TransformToggleRow(
                    transform: transform,
                    isEnabled: binding(for: transform)
                )
            }

            if monitor.isEnabled(.tablesToList) {
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel(text: "List format")

                    Picker("List format", selection: $monitor.outputFormat) {
                        ForEach(TransformOutputFormat.allCases) { format in
                            Text(format.title).tag(format)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .tint(Cotton.accent)

                    TableTransformExample(format: monitor.outputFormat)
                        .padding(.top, 4)
                }
                .padding(.top, 2)
            }
        }
    }

    private var footerRow: some View {
        HStack(spacing: 16) {
            Button("About") {
                NSApplication.shared.activate(ignoringOtherApps: true)
                NSApplication.shared.orderFrontStandardAboutPanel(nil)
            }

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .font(.system(size: 11.5, weight: .medium))
        .foregroundStyle(Surface.secondary)
        .buttonStyle(.plain)
    }

    private func binding(for sugar: Sugar) -> Binding<Bool> {
        Binding(
            get: { monitor.isEnabled(sugar) },
            set: { monitor.setSugar(sugar, enabled: $0) }
        )
    }

    private func binding(for transform: Transform) -> Binding<Bool> {
        Binding(
            get: { monitor.isEnabled(transform) },
            set: { monitor.setTransform(transform, enabled: $0) }
        )
    }

    private func intervalLabel(for interval: Double) -> String {
        switch interval {
        case 0.25:
            return "0.25s"
        case 0.5:
            return "0.5s"
        case 1.0:
            return "1.0s"
        case 1.5:
            return "1.5s"
        default:
            return String(format: "%.2fs", interval)
        }
    }
}

/// The menu-bar icon as a pure, presentational view: the crush glyph for a given keyframe plus
/// the state dot. `MenuBarStatusItemController` renders this to an `NSImage` with
/// `isTemplate = false`, so the dot's state color survives (a `MenuBarExtra` label would be
/// forced monochrome, collapsing active and idle). The glyph stays monochrome — it's drawn in
/// `Color.primary`, which the controller resolves against the menu bar's current appearance.
struct MenuBarIcon: View {
    let state: MonitorInterfaceState
    var progress: Double = 1

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            CrushGlyph(progress: progress, baseOpacity: glyphOpacity)

            // The status dot is the at-a-glance "is it on?" signal (cotton = active,
            // amber = idle, hollow = paused). It's an indicator, not the glyph, so its color
            // doesn't break the "menu-bar glyph stays monochrome" rule.
            StatusDot(state: state)
        }
        .frame(width: 18, height: 18)
    }

    // The dot carries the state; opacity just reinforces paused as clearly "off".
    private var glyphOpacity: Double {
        switch state {
        case .active: return 1.0
        case .idle:   return 0.85
        case .paused: return 0.5
        }
    }
}

/// A small corner indicator encoding the monitor state: filled cotton (active), filled amber
/// (idle), or a hollow muted ring (paused).
private struct StatusDot: View {
    let state: MonitorInterfaceState

    var body: some View {
        Circle()
            .fill(fillColor)
            .frame(width: 6, height: 6)
            .overlay(
                Circle().strokeBorder(strokeColor, lineWidth: strokeWidth)
            )
    }

    private var fillColor: Color {
        switch state {
        case .active: return Cotton.accent
        case .idle:   return Surface.idle
        case .paused: return .clear
        }
    }

    private var strokeColor: Color {
        state == .paused ? Surface.secondary : .clear
    }

    private var strokeWidth: CGFloat {
        state == .paused ? 1.5 : 0
    }
}

/// The lollipop glyph plus its "crush" keyframes: the candy squashes, shatters into cotton
/// shards that scatter, then reforms clean. Pure function of `progress` (0…1, 1 = at rest)
/// so each menu-bar snapshot renders the right frame.
private struct CrushGlyph: View {
    var progress: Double
    var baseOpacity: Double

    private static let shards: [(dx: CGFloat, dy: CGFloat, color: Color)] = {
        let candy = Cotton.candy
        return [
            (-1.0, -1.0, candy[0]),
            ( 1.0, -0.7, candy[1]),
            (-0.8,  1.0, candy[2]),
            ( 1.0,  1.0, candy[0]),
        ]
    }()

    var body: some View {
        ZStack {
            Image("Lollipop")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(Color.primary)
                .scaleEffect(CGFloat(wholeScale))
                .opacity(wholeOpacity * baseOpacity)

            ForEach(0..<Self.shards.count, id: \.self) { index in
                let shard = Self.shards[index]
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(shard.color)
                    .frame(width: 3, height: 3)
                    .scaleEffect(CGFloat(0.5 + 0.7 * shardTravel))
                    .offset(x: shard.dx * CGFloat(shardDistance),
                            y: shard.dy * CGFloat(shardDistance))
                    .opacity(shardOpacity)
            }
        }
        .frame(width: 18, height: 18)
    }

    // Whole candy: visible at rest, fades out as it shatters, fades back in on reform.
    private var wholeOpacity: Double {
        switch progress {
        case ..<0.30: return 1
        case ..<0.38: return 1 - (progress - 0.30) / 0.08
        case ..<0.82: return 0
        default:      return min(1, (progress - 0.82) / 0.18)
        }
    }

    private var wholeScale: Double {
        if progress < 0.30 {
            return 1 - 0.12 * (progress / 0.30)            // anticipation squash
        } else if progress > 0.82 {
            return 0.7 + 0.3 * easeOutBack((progress - 0.82) / 0.18)
        }
        return 1
    }

    // Shards: born at the shatter, scatter outward on an ease-out, then fade.
    private var shardTravel: Double {
        min(1, max(0, (progress - 0.30) / 0.70))
    }

    private var shardDistance: Double {
        6 * easeOut(shardTravel)
    }

    private var shardOpacity: Double {
        switch progress {
        case ..<0.30: return 0
        case ..<0.40: return (progress - 0.30) / 0.10
        case ..<0.78: return 1
        case ..<1.0:  return 1 - (progress - 0.78) / 0.22
        default:      return 0
        }
    }

    private func easeOut(_ t: Double) -> Double { 1 - pow(1 - t, 3) }
    private func easeOutBack(_ t: Double) -> Double {
        let c1 = 1.70158, c3 = c1 + 1
        return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
    }
}

/// The "cleaned" counter, with a Candy-Crush-style reward on each clean: the number pops and
/// a small cotton confetti burst fires. Lives in the popover (a real window), so it animates
/// freely — no menu-bar snapshot limit here.
private struct CleanedMetricTile: View {
    @ObservedObject var monitor: PasteboardMonitor
    @State private var pop = false

    var body: some View {
        HStack(spacing: 5) {
            ZStack {
                ConfettiBurst(trigger: monitor.cleanupPulse)

                Text("\(monitor.cleanupCount)")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(pop ? Cotton.ink : Surface.text)
                    .scaleEffect(pop ? 1.4 : 1)
            }

            Text("cleaned")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Surface.tertiary)
        }
        .onChange(of: monitor.cleanupPulse) { _ in celebrate() }
    }

    private func celebrate() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) { pop = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.25)) { pop = false }
        }
    }
}

/// A short confetti burst fired whenever `trigger` changes — cotton chips flung outward from
/// the center, fading as they go. Renders nothing at rest.
private struct ConfettiBurst: View {
    let trigger: Int

    @State private var active = false
    @State private var fly = false

    private struct Piece {
        let dx: CGFloat
        let dy: CGFloat
        let color: Color
        let rotation: Double
    }

    private static let pieces: [Piece] = {
        let candy = Cotton.candy
        return [
            Piece(dx: -16, dy: -12, color: candy[0], rotation: -120),
            Piece(dx:  12, dy: -17, color: candy[1], rotation:  140),
            Piece(dx:  21, dy:  -5, color: candy[2], rotation:   90),
            Piece(dx: -19, dy:   3, color: candy[0], rotation:  -80),
            Piece(dx:   5, dy: -21, color: candy[2], rotation:  160),
            Piece(dx:  -7, dy:  11, color: candy[1], rotation: -150),
        ]
    }()

    var body: some View {
        ZStack {
            if active {
                ForEach(0..<Self.pieces.count, id: \.self) { index in
                    let piece = Self.pieces[index]
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(piece.color)
                        .frame(width: 5, height: 5)
                        .rotationEffect(.degrees(fly ? piece.rotation : 0))
                        .scaleEffect(fly ? 1 : 0.4)
                        .offset(x: fly ? piece.dx : 0, y: fly ? piece.dy : 0)
                        .opacity(fly ? 0 : 1)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _ in burst() }
    }

    private func burst() {
        active = true
        fly = false
        // Let the pieces lay down at the center for one tick, then animate them outward.
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.55)) { fly = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            active = false
        }
    }
}

private struct SugarToggleRow: View {
    let sugar: Sugar
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: sugar.symbolName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Surface.tertiary)
                .frame(width: 16)

            Text(sugar.title)
                .font(.system(size: 12.5))
                .foregroundStyle(Surface.text)

            Text(sugar.example)
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(Surface.tertiary)

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .controlSize(.small)
                .tint(Cotton.accent)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TransformToggleRow: View {
    let transform: Transform
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: transform.symbolName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Surface.tertiary)
                .frame(width: 16)

            Text(transform.title)
                .font(.system(size: 12.5))
                .foregroundStyle(Surface.text)

            Text(transform.example)
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(Surface.tertiary)

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .controlSize(.small)
                .tint(Cotton.accent)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TableTransformExample: View {
    let format: TransformOutputFormat

    private let markdown = """
    | Setting | Value |
    |---------|-------|
    | timeout | 30    |
    | retries | 3     |
    """

    private var output: String {
        switch format {
        case .yaml:
            return """
            - Setting: timeout
              Value: 30
            - Setting: retries
              Value: 3
            """
        case .toml:
            return """
            Setting = timeout
            Value = 30

            Setting = retries
            Value = 3
            """
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ExampleCodeBlock(label: "Markdown copied", text: markdown)

            HStack(spacing: 4) {
                Rectangle()
                    .fill(Surface.hairline)
                    .frame(height: 1)

                Text("converts to")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundStyle(Surface.tertiary)

                Rectangle()
                    .fill(Surface.hairline)
                    .frame(height: 1)
            }

            ExampleCodeBlock(label: format.title, text: output)
        }
    }
}

private struct ExampleCodeBlock: View {
    let label: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                .foregroundStyle(Surface.tertiary)

            Text(text)
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(Surface.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(7)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Surface.desk.opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Surface.hairline, lineWidth: 1)
                )
        }
    }
}
