import AppKit
import Foundation
import SugarCore

// Sugar, Transform, TransformOutputFormat, the strippers, and TableConverter now
// live in the cross-platform SugarCore package (the single source of truth shared
// with the sugarfree CLI). This file keeps only the macOS clipboard plumbing.

enum MonitorInterfaceState {
    case active
    case paused
    case idle

    var title: String {
        switch self {
        case .active:
            return "Active"
        case .paused:
            return "Paused"
        case .idle:
            return "Idle"
        }
    }
}

struct CleanupEvent {
    let timestamp: Date
    let sugars: [Sugar]
    let transforms: [Transform]
    let tableCount: Int
    let itemCount: Int
    let wasManual: Bool

    var headline: String {
        let action = wasManual ? "Cleaned" : "Auto-cleaned"
        return "\(action) \(summary)"
    }

    var detail: String {
        let noun = itemCount == 1 ? "clipboard item" : "clipboard items"
        return "\(itemCount) \(noun) updated"
    }

    private var summary: String {
        var parts = sugars.map(\.title)
        if tableCount > 0 {
            parts.append(tableCount == 1 ? "1 table" : "\(tableCount) tables")
        }
        return parts.isEmpty ? "formatting" : parts.joined(separator: " + ")
    }
}

@MainActor
final class PasteboardMonitor: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: DefaultsKey.isEnabled.rawValue)
        }
    }

    /// Which sugars the user wants stripped.
    @Published var enabledSugars: Set<Sugar> {
        didSet {
            defaults.set(enabledSugars.map(\.rawValue), forKey: DefaultsKey.enabledSugars.rawValue)
        }
    }

    /// Which structural transforms the user has opted into (off by default).
    @Published var enabledTransforms: Set<Transform> {
        didSet {
            defaults.set(enabledTransforms.map(\.rawValue), forKey: DefaultsKey.enabledTransforms.rawValue)
        }
    }

    /// Output style for table → list transforms.
    @Published var outputFormat: TransformOutputFormat {
        didSet {
            defaults.set(outputFormat.rawValue, forKey: DefaultsKey.outputFormat.rawValue)
        }
    }

    @Published var pollingInterval: Double {
        didSet {
            let clampedValue = Self.allowedPollingIntervals.contains(pollingInterval) ? pollingInterval : Self.defaultPollingInterval
            if clampedValue != pollingInterval {
                pollingInterval = clampedValue
                return
            }

            defaults.set(clampedValue, forKey: DefaultsKey.pollingInterval.rawValue)
            restartMonitoring()
        }
    }

    @Published private(set) var cleanupCount: Int {
        didSet {
            defaults.set(cleanupCount, forKey: DefaultsKey.cleanupCount.rawValue)
        }
    }

    @Published private(set) var lastEvent: CleanupEvent?

    /// Bumped on every successful cleanup. Carries no data — it's a pure signal the
    /// menu-bar icon observes to fire its "just cleaned" animation.
    @Published private(set) var cleanupPulse: Int = 0

    private let defaults: UserDefaults
    private var timer: Timer?
    private var lastChangeCount: Int
    private var selfWriteCount: Int

    private enum DefaultsKey: String {
        case isEnabled
        case enabledSugars
        case enabledTransforms
        case outputFormat
        case pollingInterval
        case cleanupCount
    }

    private struct RewriteResult {
        let didChange: Bool
        let sugars: [Sugar]
        let transforms: [Transform]
        let tableCount: Int
        let itemCount: Int

        static let unchanged = RewriteResult(didChange: false, sugars: [], transforms: [], tableCount: 0, itemCount: 0)
    }

    static let allowedPollingIntervals: [Double] = [0.25, 0.5, 1.0, 1.5]
    static let defaultPollingInterval = 0.5
    /// Bold + italic are the everyday annoyances; underline/strikethrough often carry
    /// meaning, so they stay off until the user opts in.
    static let defaultSugars: Set<Sugar> = [.bold, .italic]
    /// Transforms reshape content and are lossy, so they stay off until opted into.
    static let defaultTransforms: Set<Transform> = []
    static let defaultOutputFormat: TransformOutputFormat = .yaml

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isEnabled = defaults.object(forKey: DefaultsKey.isEnabled.rawValue) as? Bool ?? true

        if let stored = defaults.array(forKey: DefaultsKey.enabledSugars.rawValue) as? [String] {
            self.enabledSugars = Set(stored.compactMap(Sugar.init(rawValue:)))
        } else {
            self.enabledSugars = Self.defaultSugars
        }

        if let storedTransforms = defaults.array(forKey: DefaultsKey.enabledTransforms.rawValue) as? [String] {
            self.enabledTransforms = Set(storedTransforms.compactMap(Transform.init(rawValue:)))
        } else {
            self.enabledTransforms = Self.defaultTransforms
        }

        let storedFormat = defaults.string(forKey: DefaultsKey.outputFormat.rawValue)
        self.outputFormat = storedFormat.flatMap(TransformOutputFormat.init(rawValue:)) ?? Self.defaultOutputFormat

        let storedInterval = defaults.object(forKey: DefaultsKey.pollingInterval.rawValue) as? Double ?? Self.defaultPollingInterval
        self.pollingInterval = Self.allowedPollingIntervals.contains(storedInterval) ? storedInterval : Self.defaultPollingInterval
        self.cleanupCount = defaults.object(forKey: DefaultsKey.cleanupCount.rawValue) as? Int ?? 0

        let currentCount = NSPasteboard.general.changeCount
        self.lastChangeCount = currentCount
        self.selfWriteCount = currentCount

        startMonitoring()
    }

    func setSugar(_ sugar: Sugar, enabled: Bool) {
        if enabled {
            enabledSugars.insert(sugar)
        } else {
            enabledSugars.remove(sugar)
        }
    }

    func isEnabled(_ sugar: Sugar) -> Bool {
        enabledSugars.contains(sugar)
    }

    func setTransform(_ transform: Transform, enabled: Bool) {
        if enabled {
            enabledTransforms.insert(transform)
        } else {
            enabledTransforms.remove(transform)
        }
    }

    func isEnabled(_ transform: Transform) -> Bool {
        enabledTransforms.contains(transform)
    }

    var hasEnabledSugars: Bool {
        !enabledSugars.isEmpty
    }

    var hasEnabledTransforms: Bool {
        !enabledTransforms.isEmpty
    }

    /// Whether there's anything for the monitor to do (any sugar or transform on).
    var hasWork: Bool {
        hasEnabledSugars || hasEnabledTransforms
    }

    var interfaceState: MonitorInterfaceState {
        if !isEnabled {
            return .paused
        }
        if !hasWork {
            return .idle
        }
        return .active
    }

    var statusHeadline: String {
        switch interfaceState {
        case .active:
            return lastEvent?.headline ?? "Watching the clipboard"
        case .paused:
            return "Automatic cleanup is paused"
        case .idle:
            return "Enable a sugar or transform"
        }
    }

    var statusDetail: String {
        switch interfaceState {
        case .active:
            if let lastEvent {
                return "\(lastEvent.detail) • checks every \(pollingIntervalLabel)"
            }
            return "Waiting for copied text to clean."
        case .paused:
            return "Clipboard changes pass through untouched until you resume."
        case .idle:
            return "Sugarfree is on, but nothing is selected to clean."
        }
    }

    var pollingIntervalLabel: String {
        switch pollingInterval {
        case 0.25:
            return "0.25s"
        case 0.5:
            return "0.5s"
        case 1.0:
            return "1.0s"
        case 1.5:
            return "1.5s"
        default:
            return String(format: "%.2fs", pollingInterval)
        }
    }

    func cleanClipboardManually() {
        guard hasWork else { return }
        _ = cleanPasteboardIfNeeded(wasManual: true)
    }

    private func startMonitoring() {
        let timer = Timer(timeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPasteboard()
            }
        }
        timer.tolerance = min(0.2, pollingInterval * 0.25)
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func restartMonitoring() {
        timer?.invalidate()
        startMonitoring()
    }

    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount

        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        guard currentCount != selfWriteCount else { return }
        guard isEnabled, hasWork else { return }

        _ = cleanPasteboardIfNeeded(wasManual: false)
    }

    @discardableResult
    private func cleanPasteboardIfNeeded(wasManual: Bool) -> Bool {
        let pasteboard = NSPasteboard.general
        let result = rewritePasteboardIfNeeded(pasteboard)

        guard result.didChange else { return false }

        cleanupCount += 1
        lastEvent = CleanupEvent(
            timestamp: Date(),
            sugars: result.sugars,
            transforms: result.transforms,
            tableCount: result.tableCount,
            itemCount: result.itemCount,
            wasManual: wasManual
        )
        cleanupPulse &+= 1
        selfWriteCount = pasteboard.changeCount
        lastChangeCount = pasteboard.changeCount
        return true
    }

    private func rewritePasteboardIfNeeded(_ pasteboard: NSPasteboard) -> RewriteResult {
        guard let originalItems = pasteboard.pasteboardItems, !originalItems.isEmpty else {
            return .unchanged
        }

        let sugars = enabledSugars
        let convertTables = enabledTransforms.contains(.tablesToList)
        let format = outputFormat.converterFormat

        var updatedItems: [NSPasteboardItem] = []
        var removedSugars = Set<Sugar>()
        var appliedTransforms = Set<Transform>()
        var tableCount = 0

        for originalItem in originalItems {
            let updatedItem = NSPasteboardItem()
            var copiedAnyType = false
            // A converted table makes the RTF representation stale (we don't parse RTF
            // tables); we drop RTF in that case so rich targets fall back to the
            // converted HTML/plain text instead of pasting the original table.
            var transformFiredInItem = false
            var itemTableCount = 0
            // RTF is deferred until we know whether a transform fired elsewhere.
            var rtfData: Data?

            for type in originalItem.types {
                if type == .rtf {
                    rtfData = originalItem.data(forType: type)
                    continue
                }

                if type == .html, let originalData = originalItem.data(forType: type) {
                    let originalHTML = decodeClipboardString(from: originalData)
                    let (strippedHTML, removed) = stripHTML(originalHTML, sugars: sugars)
                    var html = strippedHTML
                    if convertTables {
                        let (converted, count) = TableConverter.convertHTMLTables(in: html, format: format)
                        if count > 0 {
                            html = converted
                            transformFiredInItem = true
                            appliedTransforms.insert(.tablesToList)
                            itemTableCount = max(itemTableCount, count)
                        }
                    }

                    if html != originalHTML, let processedData = html.data(using: .utf8) {
                        _ = updatedItem.setData(processedData, forType: type)
                        removedSugars.formUnion(removed)
                    } else {
                        _ = updatedItem.setData(originalData, forType: type)
                    }
                    copiedAnyType = true
                    continue
                }

                if type == .string, let originalString = originalItem.string(forType: type) {
                    let (strippedString, removed) = stripPlainText(originalString, sugars: sugars)
                    var string = strippedString
                    if convertTables {
                        let (converted, count) = TableConverter.convertMarkdownTables(in: string, format: format)
                        if count > 0 {
                            string = converted
                            transformFiredInItem = true
                            appliedTransforms.insert(.tablesToList)
                            itemTableCount = max(itemTableCount, count)
                        }
                    }

                    if string != originalString {
                        _ = updatedItem.setString(string, forType: type)
                        removedSugars.formUnion(removed)
                    } else if let originalData = originalItem.data(forType: type) {
                        _ = updatedItem.setData(originalData, forType: type)
                    } else {
                        _ = updatedItem.setString(originalString, forType: type)
                    }
                    copiedAnyType = true
                    continue
                }

                if let originalData = originalItem.data(forType: type) {
                    _ = updatedItem.setData(originalData, forType: type)
                    copiedAnyType = true
                    continue
                }

                if let originalString = originalItem.string(forType: type) {
                    _ = updatedItem.setString(originalString, forType: type)
                    copiedAnyType = true
                }
            }

            // Replay the deferred RTF: strip it normally, unless a table conversion
            // fired in this item — then drop it so the converted reps win.
            if let rtfData, !(convertTables && transformFiredInItem) {
                let (processed, removed) = stripRTF(rtfData, sugars: sugars)
                if let processed, !removed.isEmpty {
                    _ = updatedItem.setData(processed, forType: .rtf)
                    removedSugars.formUnion(removed)
                } else {
                    _ = updatedItem.setData(rtfData, forType: .rtf)
                }
                copiedAnyType = true
            }

            tableCount += itemTableCount

            if copiedAnyType {
                updatedItems.append(updatedItem)
            }
        }

        guard !removedSugars.isEmpty || !appliedTransforms.isEmpty, !updatedItems.isEmpty else {
            return .unchanged
        }

        pasteboard.clearContents()
        pasteboard.writeObjects(updatedItems)

        let orderedSugars = Sugar.allCases.filter { removedSugars.contains($0) }
        let orderedTransforms = Transform.allCases.filter { appliedTransforms.contains($0) }
        return RewriteResult(
            didChange: true,
            sugars: orderedSugars,
            transforms: orderedTransforms,
            tableCount: tableCount,
            itemCount: updatedItems.count
        )
    }

    private func decodeClipboardString(from data: Data) -> String {
        if let utf8String = String(data: data, encoding: .utf8) {
            return utf8String
        }
        if let unicodeString = String(data: data, encoding: .unicode) {
            return unicodeString
        }
        return String(decoding: data, as: UTF8.self)
    }
}
