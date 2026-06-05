import XCTest

/// Covers the shared (AppKit-free) plain-text and HTML strippers that back both
/// the menu-bar app and the `sugarfree` CLI.
final class SugarStripperTests: XCTestCase {

    // MARK: - Plain text / markdown

    func testStripsBoldAndItalicMarkers() {
        let (out, removed) = SugarStripper.stripPlainText("**bold** and *italic*", sugars: [.bold, .italic])
        XCTAssertEqual(out, "bold and italic")
        XCTAssertEqual(removed, [.bold, .italic])
    }

    func testBoldRunsBeforeItalicSoDoubleStarsSurvive() {
        // Stripping only italic must not chew a `**bold**` run into `*bold*`.
        let (out, removed) = SugarStripper.stripPlainText("**bold**", sugars: [.italic])
        XCTAssertEqual(out, "**bold**")
        XCTAssertTrue(removed.isEmpty)
    }

    func testUnselectedSugarsAreLeftAlone() {
        let (out, removed) = SugarStripper.stripPlainText("**bold** ~~strike~~", sugars: [.bold])
        XCTAssertEqual(out, "bold ~~strike~~")
        XCTAssertEqual(removed, [.bold])
    }

    func testSnakeCaseSurvivesItalicStripping() {
        let (out, _) = SugarStripper.stripPlainText("call some_function now", sugars: [.italic])
        XCTAssertEqual(out, "call some_function now")
    }

    func testStripsAtxHeadingKeepingText() {
        let (out, removed) = SugarStripper.stripPlainText("# Title\nbody", sugars: [.heading])
        XCTAssertEqual(out, "Title\nbody")
        XCTAssertEqual(removed, [.heading])
    }

    func testHashTagIsNotAHeading() {
        let (out, removed) = SugarStripper.stripPlainText("#tag and issue #42", sugars: [.heading])
        XCTAssertEqual(out, "#tag and issue #42")
        XCTAssertTrue(removed.isEmpty)
    }

    func testStrikethroughMarkers() {
        let (out, removed) = SugarStripper.stripPlainText("~~gone~~", sugars: [.strikethrough])
        XCTAssertEqual(out, "gone")
        XCTAssertEqual(removed, [.strikethrough])
    }

    func testEmptySugarSetIsNoOp() {
        let (out, removed) = SugarStripper.stripPlainText("**bold**", sugars: [])
        XCTAssertEqual(out, "**bold**")
        XCTAssertTrue(removed.isEmpty)
    }

    // MARK: - HTML

    func testUnwrapsBoldAndItalicTags() {
        let (out, removed) = SugarStripper.stripHTML("<strong>a</strong> <em>b</em>", sugars: [.bold, .italic])
        XCTAssertEqual(out, "a b")
        XCTAssertEqual(removed, [.bold, .italic])
    }

    func testDropsInlineFontWeightStyle() {
        let (out, removed) = SugarStripper.stripHTML("<span style=\"font-weight:700;\">x</span>", sugars: [.bold])
        XCTAssertEqual(out, "<span style=\"\">x</span>")
        XCTAssertEqual(removed, [.bold])
    }

    func testUnwrapsHeadingTags() {
        let (out, removed) = SugarStripper.stripHTML("<h2>Title</h2>", sugars: [.heading])
        XCTAssertEqual(out, "Title")
        XCTAssertEqual(removed, [.heading])
    }

    func testHTMLLeavesUnselectedSugars() {
        let (out, removed) = SugarStripper.stripHTML("<u>keep</u> <b>drop</b>", sugars: [.bold])
        XCTAssertEqual(out, "<u>keep</u> drop")
        XCTAssertEqual(removed, [.bold])
    }
}
