import AppKit
import Foundation

enum ClipboardFormat: String, CaseIterable, Identifiable {
    case richText
    case html
    case markdown

    var id: Self { self }

    var title: String {
        switch self {
        case .richText:
            return "Rich Text"
        case .html:
            return "HTML"
        case .markdown:
            return "Markdown"
        }
    }

    var detail: String {
        switch self {
        case .richText:
            return "Removes bold font traits from RTF clipboard data."
        case .html:
            return "Strips bold tags and font-weight styles from HTML."
        case .markdown:
            return "Removes ** and __ markers from plain text."
        }
    }

    var symbolName: String {
        switch self {
        case .richText:
            return "textformat"
        case .html:
            return "chevron.left.forwardslash.chevron.right"
        case .markdown:
            return "number.square"
        }
    }
}

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
    let formats: [ClipboardFormat]
    let itemCount: Int
    let wasManual: Bool

    var headline: String {
        let action = wasManual ? "Cleaned" : "Auto-cleaned"
        return "\(action) \(formatSummary)"
    }

    var detail: String {
        let noun = itemCount == 1 ? "clipboard item" : "clipboard items"
        return "\(itemCount) \(noun) updated"
    }

    private var formatSummary: String {
        formats.map(\.title).joined(separator: " + ")
    }
}

@MainActor
final class PasteboardMonitor: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: DefaultsKey.isEnabled.rawValue)
        }
    }

    @Published var stripsRTF: Bool {
        didSet {
            defaults.set(stripsRTF, forKey: DefaultsKey.stripsRTF.rawValue)
        }
    }

    @Published var stripsHTML: Bool {
        didSet {
            defaults.set(stripsHTML, forKey: DefaultsKey.stripsHTML.rawValue)
        }
    }

    @Published var stripsMarkdown: Bool {
        didSet {
            defaults.set(stripsMarkdown, forKey: DefaultsKey.stripsMarkdown.rawValue)
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

    private let defaults: UserDefaults
    private var timer: Timer?
    private var lastChangeCount: Int
    private var selfWriteCount: Int

    private enum DefaultsKey: String {
        case isEnabled
        case stripsRTF
        case stripsHTML
        case stripsMarkdown
        case pollingInterval
        case cleanupCount
    }

    private struct RewriteResult {
        let didChange: Bool
        let formats: [ClipboardFormat]
        let itemCount: Int

        static let unchanged = RewriteResult(didChange: false, formats: [], itemCount: 0)
    }

    static let allowedPollingIntervals: [Double] = [0.25, 0.5, 1.0, 1.5]
    static let defaultPollingInterval = 0.5

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isEnabled = defaults.object(forKey: DefaultsKey.isEnabled.rawValue) as? Bool ?? true
        self.stripsRTF = defaults.object(forKey: DefaultsKey.stripsRTF.rawValue) as? Bool ?? true
        self.stripsHTML = defaults.object(forKey: DefaultsKey.stripsHTML.rawValue) as? Bool ?? true
        self.stripsMarkdown = defaults.object(forKey: DefaultsKey.stripsMarkdown.rawValue) as? Bool ?? true

        let storedInterval = defaults.object(forKey: DefaultsKey.pollingInterval.rawValue) as? Double ?? Self.defaultPollingInterval
        self.pollingInterval = Self.allowedPollingIntervals.contains(storedInterval) ? storedInterval : Self.defaultPollingInterval
        self.cleanupCount = defaults.object(forKey: DefaultsKey.cleanupCount.rawValue) as? Int ?? 0

        let currentCount = NSPasteboard.general.changeCount
        self.lastChangeCount = currentCount
        self.selfWriteCount = currentCount

        startMonitoring()
    }

    var enabledFormats: [ClipboardFormat] {
        var formats: [ClipboardFormat] = []

        if stripsRTF {
            formats.append(.richText)
        }
        if stripsHTML {
            formats.append(.html)
        }
        if stripsMarkdown {
            formats.append(.markdown)
        }

        return formats
    }

    var hasEnabledFormats: Bool {
        !enabledFormats.isEmpty
    }

    var interfaceState: MonitorInterfaceState {
        if !isEnabled {
            return .paused
        }
        if !hasEnabledFormats {
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
            return "Enable at least one clipboard format"
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
        guard hasEnabledFormats else { return }
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
        guard isEnabled, hasEnabledFormats else { return }

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
            formats: result.formats,
            itemCount: result.itemCount,
            wasManual: wasManual
        )
        selfWriteCount = pasteboard.changeCount
        lastChangeCount = pasteboard.changeCount
        return true
    }

    private func rewritePasteboardIfNeeded(_ pasteboard: NSPasteboard) -> RewriteResult {
        guard let originalItems = pasteboard.pasteboardItems, !originalItems.isEmpty else {
            return .unchanged
        }

        var updatedItems: [NSPasteboardItem] = []
        var changedFormats = Set<ClipboardFormat>()

        for originalItem in originalItems {
            let updatedItem = NSPasteboardItem()
            var copiedAnyType = false

            for type in originalItem.types {
                if type == .rtf, stripsRTF, let originalData = originalItem.data(forType: type) {
                    if let processedData = stripBoldFromRTF(originalData) {
                        _ = updatedItem.setData(processedData, forType: type)
                        changedFormats.insert(.richText)
                    } else {
                        _ = updatedItem.setData(originalData, forType: type)
                    }
                    copiedAnyType = true
                    continue
                }

                if type == .html, stripsHTML, let originalData = originalItem.data(forType: type) {
                    let originalHTML = decodeClipboardString(from: originalData)
                    let processedHTML = stripBoldFromHTML(originalHTML)

                    if processedHTML != originalHTML, let processedData = processedHTML.data(using: .utf8) {
                        _ = updatedItem.setData(processedData, forType: type)
                        changedFormats.insert(.html)
                    } else {
                        _ = updatedItem.setData(originalData, forType: type)
                    }
                    copiedAnyType = true
                    continue
                }

                if type == .string, stripsMarkdown, let originalString = originalItem.string(forType: type) {
                    let processedString = stripBoldFromPlainText(originalString)

                    if processedString != originalString {
                        _ = updatedItem.setString(processedString, forType: type)
                        changedFormats.insert(.markdown)
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

            if copiedAnyType {
                updatedItems.append(updatedItem)
            }
        }

        guard !changedFormats.isEmpty, !updatedItems.isEmpty else {
            return .unchanged
        }

        pasteboard.clearContents()
        pasteboard.writeObjects(updatedItems)

        let orderedFormats = ClipboardFormat.allCases.filter { changedFormats.contains($0) }
        return RewriteResult(didChange: true, formats: orderedFormats, itemCount: updatedItems.count)
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

    private func stripBoldFromRTF(_ data: Data) -> Data? {
        guard let attributedString = NSMutableAttributedString(rtf: data, documentAttributes: nil) else {
            return nil
        }

        let fullRange = NSRange(location: 0, length: attributedString.length)
        var changed = false

        attributedString.enumerateAttribute(.font, in: fullRange, options: []) { value, range, _ in
            guard let font = value as? NSFont else { return }
            let descriptor = font.fontDescriptor
            let traits = descriptor.symbolicTraits

            guard traits.contains(.bold) else { return }

            var updatedTraits = traits
            updatedTraits.remove(.bold)

            let updatedDescriptor = descriptor.withSymbolicTraits(updatedTraits)
            let updatedFont = NSFont(descriptor: updatedDescriptor, size: font.pointSize) ?? font
            attributedString.addAttribute(.font, value: updatedFont, range: range)
            changed = true
        }

        guard changed else { return nil }
        return attributedString.rtf(from: fullRange, documentAttributes: [:])
    }

    private func stripBoldFromHTML(_ html: String) -> String {
        var result = html

        result = result.replacingOccurrences(
            of: "<strong[^>]*>(.*?)</strong>",
            with: "$1",
            options: [.regularExpression, .caseInsensitive]
        )

        result = result.replacingOccurrences(
            of: "<b[^>]*>(.*?)</b>",
            with: "$1",
            options: [.regularExpression, .caseInsensitive]
        )

        result = result.replacingOccurrences(
            of: "font-weight\\s*:\\s*[^;\"']+;?",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )

        return result
    }

    private func stripBoldFromPlainText(_ text: String) -> String {
        var result = text

        result = result.replacingOccurrences(
            of: "\\*\\*(.+?)\\*\\*",
            with: "$1",
            options: .regularExpression
        )

        result = result.replacingOccurrences(
            of: "__(.+?)__",
            with: "$1",
            options: .regularExpression
        )

        return result
    }
}
