import XCTest
@testable import SugarCore

final class StripTests: XCTestCase {

    // MARK: - Plain text / markdown

    func testBoldAndItalicStrippedByDefault() {
        let (out, removed) = stripPlainText("**bold** and *italic*", sugars: [.bold, .italic])
        XCTAssertEqual(out, "bold and italic")
        XCTAssertEqual(removed, [.bold, .italic])
    }

    func testUnderscoreSnakeCaseSurvives() {
        let (out, removed) = stripPlainText("call some_function_name now", sugars: [.italic])
        XCTAssertEqual(out, "call some_function_name now")
        XCTAssertTrue(removed.isEmpty)
    }

    func testStrikethroughMarkers() {
        let (out, removed) = stripPlainText("~~gone~~", sugars: [.strikethrough])
        XCTAssertEqual(out, "gone")
        XCTAssertEqual(removed, [.strikethrough])
    }

    func testHeadingAtLineStartStripped() {
        let (out, removed) = stripPlainText("## Title", sugars: [.heading])
        XCTAssertEqual(out, "Title")
        XCTAssertEqual(removed, [.heading])
    }

    func testHashWithoutSpaceSurvives() {
        let (out, removed) = stripPlainText("#tag and C# and issue #42", sugars: [.heading])
        XCTAssertEqual(out, "#tag and C# and issue #42")
        XCTAssertTrue(removed.isEmpty)
    }

    func testHorizontalRuleLineStripped() {
        let (out, removed) = stripPlainText("a\n---\nb", sugars: [.horizontalRule])
        XCTAssertEqual(out, "a\nb")
        XCTAssertEqual(removed, [.horizontalRule])
    }

    func testHorizontalRuleVariantsStripped() {
        let (out, removed) = stripPlainText("***\ntext\n___\n* * *", sugars: [.horizontalRule])
        XCTAssertEqual(out, "text\n")
        XCTAssertEqual(removed, [.horizontalRule])
    }

    func testHorizontalRuleLeavesEmphasisAlone() {
        let (out, removed) = stripPlainText("**bold** and ---", sugars: [.horizontalRule])
        XCTAssertEqual(out, "**bold** and ---")
        XCTAssertTrue(removed.isEmpty)
    }

    func testDisabledSugarIsLeftAlone() {
        let (out, removed) = stripPlainText("**bold** *italic*", sugars: [.italic])
        XCTAssertEqual(out, "**bold** italic")
        XCTAssertEqual(removed, [.italic])
    }

    // MARK: - HTML

    func testHTMLBoldAndItalicUnwrapped() {
        let (out, removed) = stripHTML("<strong>a</strong> <em>b</em>", sugars: [.bold, .italic])
        XCTAssertEqual(out, "a b")
        XCTAssertEqual(removed, [.bold, .italic])
    }

    func testHTMLHeadingUnwrapsToText() {
        let (out, removed) = stripHTML("<h2>Title</h2>", sugars: [.heading])
        XCTAssertEqual(out, "Title")
        XCTAssertEqual(removed, [.heading])
    }

    func testHTMLFontWeightStyleRemoved() {
        let (out, removed) = stripHTML("<span style=\"font-weight: 700;\">x</span>", sugars: [.bold])
        XCTAssertEqual(out, "<span style=\"\">x</span>")
        XCTAssertEqual(removed, [.bold])
    }

    func testHTMLHorizontalRuleRemoved() {
        let (out, removed) = stripHTML("<p>a</p><hr/><p>b</p>", sugars: [.horizontalRule])
        XCTAssertEqual(out, "<p>a</p><p>b</p>")
        XCTAssertEqual(removed, [.horizontalRule])
    }

    func testHTMLUnchangedWhenNothingMatches() {
        let (out, removed) = stripHTML("<p>plain</p>", sugars: Set(Sugar.allCases))
        XCTAssertEqual(out, "<p>plain</p>")
        XCTAssertTrue(removed.isEmpty)
    }
}
