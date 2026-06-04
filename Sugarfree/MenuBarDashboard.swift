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

            MetricTile(title: "cleaned", value: "\(monitor.cleanupCount)")
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

            Text("⌘⇧P toggle · ⌘⇧K clean")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Surface.tertiary)
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

struct MenuBarStatusIcon: View {
    @ObservedObject var monitor: PasteboardMonitor

    /// One-shot cleanup cue. A MenuBarExtra label is snapshotted (no frame-driven
    /// animation in the menu bar), so the cue is a simple discrete swap: on a clean the
    /// glyph flips to the cotton-pink `lollipop-off` mark, then resets after a beat.
    @State private var sliced = false

    private var state: MonitorInterfaceState { monitor.interfaceState }

    var body: some View {
        Image(sliced ? "LollipopOff" : "Lollipop")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
            .foregroundStyle(sliced ? Cotton.accent : Color.primary)
            // Auto-cleanup ON reads at full strength; OFF (paused) mutes the glyph so the
            // menu bar shows at a glance that cleanup is off.
            .opacity(glyphOpacity)
            .accessibilityLabel(accessibilityLabel)
            .onChange(of: monitor.cleanupPulse) { _ in flashSlice() }
    }

    private func flashSlice() {
        sliced = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            sliced = false
        }
    }

    // ON (active) = full; idle (on, nothing selected) = dimmed; OFF (paused) = muted.
    private var glyphOpacity: Double {
        switch state {
        case .active:
            return 1.0
        case .idle:
            return 0.6
        case .paused:
            return 0.35
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .active:
            return "Sugarfree active"
        case .paused:
            return "Sugarfree paused"
        case .idle:
            return "Sugarfree needs a format enabled"
        }
    }
}

private struct MetricTile: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 5) {
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundStyle(Surface.text)

            Text(title)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Surface.tertiary)
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
