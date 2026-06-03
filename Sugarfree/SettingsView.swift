import SwiftUI

struct SettingsView: View {
    @ObservedObject var monitor: PasteboardMonitor

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                monitoringCard
                formatsCard
                activityCard
            }
            .padding(20)
        }
        .frame(width: 480, height: 520)
        .background(Ink.desk)
    }

    private var header: some View {
        HStack(spacing: 12) {
            BrandMark(size: 38)

            VStack(alignment: .leading, spacing: 3) {
                Wordmark(size: 26)
                Text("Strip formatting sugar from copied text.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Ink.secondary)
            }

            Spacer()

            StatusPill(state: monitor.interfaceState)
        }
        .inkSheet()
    }

    private var monitoringCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Monitoring")

            Toggle("Automatic cleanup", isOn: $monitor.isEnabled)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Ink.text)
                .tint(Cotton.accent)

            VStack(alignment: .leading, spacing: 8) {
                Text("Polling interval")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Ink.text)

                Picker("Polling interval", selection: $monitor.pollingInterval) {
                    ForEach(PasteboardMonitor.allowedPollingIntervals, id: \.self) { interval in
                        Text(label(for: interval)).tag(interval)
                    }
                }
                .pickerStyle(.segmented)
                .tint(Cotton.accent)

                Text("0.5s is a good default — fast enough without hammering the pasteboard.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Ink.tertiary)
            }
        }
        .inkSheet()
    }

    private var formatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Formats to strip")

            FormatPreferenceRow(
                title: ClipboardFormat.richText.title,
                detail: ClipboardFormat.richText.detail,
                systemImage: ClipboardFormat.richText.symbolName,
                isEnabled: $monitor.stripsRTF
            )

            FormatPreferenceRow(
                title: ClipboardFormat.html.title,
                detail: ClipboardFormat.html.detail,
                systemImage: ClipboardFormat.html.symbolName,
                isEnabled: $monitor.stripsHTML
            )

            FormatPreferenceRow(
                title: ClipboardFormat.markdown.title,
                detail: ClipboardFormat.markdown.detail,
                systemImage: ClipboardFormat.markdown.symbolName,
                isEnabled: $monitor.stripsMarkdown
            )
        }
        .inkSheet()
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "Activity")

            HStack {
                Text("Total cleanups")
                    .font(.system(size: 12))
                    .foregroundStyle(Ink.secondary)
                Spacer()
                Text("\(monitor.cleanupCount)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Ink.text)
            }

            HStack(alignment: .top) {
                Text("Last action")
                    .font(.system(size: 12))
                    .foregroundStyle(Ink.secondary)
                Spacer()
                if let lastEvent = monitor.lastEvent {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(lastEvent.headline)
                            .foregroundStyle(Ink.text)
                        Text(lastEvent.timestamp, style: .relative)
                            .foregroundStyle(Ink.tertiary)
                    }
                    .font(.system(size: 11.5))
                } else {
                    Text("—")
                        .font(.system(size: 12))
                        .foregroundStyle(Ink.tertiary)
                }
            }

            InkRule()
                .padding(.vertical, 2)

            Button {
                monitor.cleanClipboardManually()
            } label: {
                Text("Clean Now")
            }
            .buttonStyle(InkPrimaryButtonStyle())
            .disabled(!monitor.hasEnabledFormats)
        }
        .inkSheet()
    }

    private func label(for interval: Double) -> String {
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

private struct FormatPreferenceRow: View {
    let title: String
    let detail: String
    let systemImage: String
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Ink.tertiary)
                .frame(width: 18)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Ink.text)
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(Ink.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .controlSize(.small)
                .tint(Cotton.accent)
        }
    }
}
