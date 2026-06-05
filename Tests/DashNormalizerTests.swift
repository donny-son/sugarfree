import XCTest

final class DashNormalizerTests: XCTestCase {

    private let em = "\u{2014}" // —
    private let en = "\u{2013}" // –

    // MARK: - Plain text: em-dash

    func testUnspacedEmDashBecomesSpacedHyphen() {
        let (out, changed) = DashNormalizer.normalizePlainText("wait\(em)what?", kinds: [.emDash])
        XCTAssertEqual(out, "wait - what?")
        XCTAssertEqual(changed, [.emDash])
    }

    func testSpacedEmDashCollapsesSurroundingSpaces() {
        let (out, _) = DashNormalizer.normalizePlainText("the cat \(em) black \(em) ran", kinds: [.emDash])
        XCTAssertEqual(out, "the cat - black - ran")
    }

    func testOverSpacedEmDashCollapses() {
        let (out, _) = DashNormalizer.normalizePlainText("a   \(em)   b", kinds: [.emDash])
        XCTAssertEqual(out, "a - b")
    }

    func testMultipleEmDashesOnOneLine() {
        let (out, _) = DashNormalizer.normalizePlainText("a\(em)b\(em)c", kinds: [.emDash])
        XCTAssertEqual(out, "a - b - c")
    }

    // MARK: - Plain text: en-dash

    func testEnDashRangeNormalizes() {
        let (out, changed) = DashNormalizer.normalizePlainText("pages 10\(en)20", kinds: [.enDash])
        XCTAssertEqual(out, "pages 10 - 20")
        XCTAssertEqual(changed, [.enDash])
    }

    // MARK: - Independent toggling

    func testDisabledKindIsLeftUntouched() {
        // Em on, en off: the en-dash must survive.
        let (out, changed) = DashNormalizer.normalizePlainText("a\(em)b and 10\(en)20", kinds: [.emDash])
        XCTAssertEqual(out, "a - b and 10\(en)20")
        XCTAssertEqual(changed, [.emDash])
    }

    func testNoEnabledKindsIsNoOp() {
        let input = "a\(em)b 10\(en)20"
        let (out, changed) = DashNormalizer.normalizePlainText(input, kinds: [])
        XCTAssertEqual(out, input)
        XCTAssertTrue(changed.isEmpty)
    }

    func testReportsNoChangeWhenNoDashPresent() {
        let (out, changed) = DashNormalizer.normalizePlainText("plain hyphen-ated text", kinds: [.emDash, .enDash])
        XCTAssertEqual(out, "plain hyphen-ated text")
        XCTAssertTrue(changed.isEmpty)
    }

    // MARK: - Newline preservation

    func testNewlinesArePreserved() {
        // Only spaces/tabs around the dash are absorbed — line breaks survive.
        let (out, _) = DashNormalizer.normalizePlainText("first\(em)line\nsecond\(em)line", kinds: [.emDash])
        XCTAssertEqual(out, "first - line\nsecond - line")
    }

    // MARK: - Idempotency

    func testIdempotent() {
        let (once, _) = DashNormalizer.normalizePlainText("wait\(em)what \(en) ok", kinds: [.emDash, .enDash])
        let (twice, changed) = DashNormalizer.normalizePlainText(once, kinds: [.emDash, .enDash])
        XCTAssertEqual(once, twice)
        XCTAssertTrue(changed.isEmpty, "Re-running on already-normalized text must change nothing")
    }

    // MARK: - HTML entities

    func testHTMLLiteralEmDash() {
        let (out, changed) = DashNormalizer.normalizeHTML("<p>a\(em)b</p>", kinds: [.emDash])
        XCTAssertEqual(out, "<p>a - b</p>")
        XCTAssertEqual(changed, [.emDash])
    }

    func testHTMLNamedEntity() {
        let (out, changed) = DashNormalizer.normalizeHTML("a&mdash;b", kinds: [.emDash])
        XCTAssertEqual(out, "a - b")
        XCTAssertEqual(changed, [.emDash])
    }

    func testHTMLDecimalEntity() {
        let (out, _) = DashNormalizer.normalizeHTML("a&#8212;b", kinds: [.emDash])
        XCTAssertEqual(out, "a - b")
    }

    func testHTMLHexEntityCaseInsensitive() {
        let (lower, _) = DashNormalizer.normalizeHTML("a&#x2014;b", kinds: [.emDash])
        let (upper, _) = DashNormalizer.normalizeHTML("a&#X2014;b", kinds: [.emDash])
        XCTAssertEqual(lower, "a - b")
        XCTAssertEqual(upper, "a - b")
    }

    func testHTMLEnDashEntity() {
        let (out, changed) = DashNormalizer.normalizeHTML("10&ndash;20", kinds: [.enDash])
        XCTAssertEqual(out, "10 - 20")
        XCTAssertEqual(changed, [.enDash])
    }

    func testHTMLEntityWithSurroundingSpacesCollapses() {
        let (out, _) = DashNormalizer.normalizeHTML("a &mdash; b", kinds: [.emDash])
        XCTAssertEqual(out, "a - b")
    }
}
