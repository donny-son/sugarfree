import AppKit
import SwiftUI

struct MenuBarDashboard: View {
    @ObservedObject var monitor: PasteboardMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            brandRow
            statusSection
            InkRule()
            controlSection
            InkRule()
            formatsSection
            InkRule()
            footerRow
        }
        .inkSheet(padding: 16)
        .padding(14)
        .frame(width: 320)
        .background(Ink.desk)
    }

    private var brandRow: some View {
        HStack(spacing: 10) {
            BrandMark(size: 26)

            Wordmark(size: 22)

            Spacer()

            StatusPill(state: monitor.interfaceState)
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monitor.statusHeadline)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Ink.text)

            Text(monitor.statusDetail)
                .font(.system(size: 11.5))
                .foregroundStyle(Ink.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 22) {
                MetricTile(title: "cleaned", value: "\(monitor.cleanupCount)")
                MetricTile(title: "interval", value: monitor.pollingIntervalLabel)
            }
            .padding(.top, 2)

            if let lastEvent = monitor.lastEvent {
                HStack(spacing: 4) {
                    Text(lastEvent.detail)
                    Text("·")
                    Text(lastEvent.timestamp, style: .relative)
                }
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(Ink.tertiary)
            }
        }
    }

    private var controlSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Automatic cleanup", isOn: $monitor.isEnabled)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Ink.text)
                .toggleStyle(.switch)
                .tint(Cotton.accent)

            Button {
                monitor.cleanClipboardManually()
            } label: {
                Text("Clean Now")
            }
            .buttonStyle(CottonPrimaryButtonStyle())
            .disabled(!monitor.hasEnabledSugars)

            Text("⌘⇧P toggle · ⌘⇧K clean")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Ink.tertiary)
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

    private var footerRow: some View {
        HStack(spacing: 16) {
            Button("About") {
                NSApplication.shared.activate(ignoringOtherApps: true)
                NSApplication.shared.orderFrontStandardAboutPanel(nil)
            }

            Button("Settings…") {
                NSApplication.shared.activate(ignoringOtherApps: true)
                NSApplication.shared.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .font(.system(size: 11.5, weight: .medium))
        .foregroundStyle(Ink.secondary)
        .buttonStyle(.plain)
    }

    private func binding(for sugar: Sugar) -> Binding<Bool> {
        Binding(
            get: { monitor.isEnabled(sugar) },
            set: { monitor.setSugar(sugar, enabled: $0) }
        )
    }
}

struct MenuBarStatusIcon: View {
    let state: MonitorInterfaceState

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("LollipopOff")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)

            Circle()
                .fill(badgeColor)
                .frame(width: 5, height: 5)
                .offset(x: 2, y: 1)
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var badgeColor: Color {
        switch state {
        case .active:
            return Cotton.accent
        case .paused:
            return .secondary
        case .idle:
            return Ink.idle
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
                .foregroundStyle(Ink.text)

            Text(title)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Ink.tertiary)
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
                .foregroundStyle(Ink.tertiary)
                .frame(width: 16)

            Text(sugar.title)
                .font(.system(size: 12.5))
                .foregroundStyle(Ink.text)

            Text(sugar.example)
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(Ink.tertiary)

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .controlSize(.small)
                .tint(Cotton.accent)
        }
        .accessibilityElement(children: .combine)
    }
}
