import XCTest

final class TableConverterTests: XCTestCase {

    // MARK: - Markdown → YAML

    func testMarkdownTwoColumnYAML() {
        let md = """
        | Setting | Value |
        |---------|-------|
        | timeout | 30 |
        | retries | 3 |
        """
        let (out, count) = TableConverter.convertMarkdownTables(in: md, format: .yaml)
        XCTAssertEqual(count, 1)
        XCTAssertEqual(out, """
        - Setting: timeout
          Value: "30"
        - Setting: retries
          Value: "3"
        """)
    }

    func testMarkdownThreeColumnYAML() {
        let md = """
        | Name | Age | City |
        |------|-----|------|
        | Ann | 30 | NYC |
        """
        let (out, count) = TableConverter.convertMarkdownTables(in: md, format: .yaml)
        XCTAssertEqual(count, 1)
        XCTAssertEqual(out, """
        - Name: Ann
          Age: "30"
          City: NYC
        """)
    }

    // MARK: - Markdown → TOML

    func testMarkdownTwoColumnTOML() {
        let md = """
        | Setting | Value |
        |---------|-------|
        | timeout | 30 |
        """
        let (out, count) = TableConverter.convertMarkdownTables(in: md, format: .toml)
        XCTAssertEqual(count, 1)
        XCTAssertEqual(out, """
        [[rows]]
        Setting = "timeout"
        Value = "30"
        """)
    }

    func testTOMLQuotesNonBareHeaderKey() {
        let md = """
        | Full Name | Age |
        |-----------|-----|
        | Ann Lee | 30 |
        """
        let (out, _) = TableConverter.convertMarkdownTables(in: md, format: .toml)
        XCTAssertEqual(out, """
        [[rows]]
        "Full Name" = "Ann Lee"
        Age = "30"
        """)
    }

    // MARK: - Surrounding content & multiple tables

    func testSurroundingTextAndBlankLinesPreserved() {
        let md = """
        Intro line

        | A | B |
        |---|---|
        | 1 | 2 |

        Outro
        """
        let (out, count) = TableConverter.convertMarkdownTables(in: md, format: .yaml)
        XCTAssertEqual(count, 1)
        XCTAssertEqual(out, """
        Intro line

        - A: "1"
          B: "2"

        Outro
        """)
    }

    func testMultipleTablesCounted() {
        let md = """
        | A | B |
        |---|---|
        | 1 | 2 |

        | C | D |
        |---|---|
        | 3 | 4 |
        """
        let (_, count) = TableConverter.convertMarkdownTables(in: md, format: .yaml)
        XCTAssertEqual(count, 2)
    }

    func testConversionIsIdempotent() {
        let md = """
        | A | B |
        |---|---|
        | 1 | 2 |
        """
        let (once, firstCount) = TableConverter.convertMarkdownTables(in: md, format: .yaml)
        XCTAssertEqual(firstCount, 1)
        let (twice, secondCount) = TableConverter.convertMarkdownTables(in: once, format: .yaml)
        XCTAssertEqual(secondCount, 0)
        XCTAssertEqual(once, twice)
    }

    // MARK: - Parsing details

    func testTableWithoutOuterPipes() {
        let md = """
        A | B
        ---|---
        1 | 2
        """
        let (out, count) = TableConverter.convertMarkdownTables(in: md, format: .yaml)
        XCTAssertEqual(count, 1)
        XCTAssertEqual(out, """
        - A: "1"
          B: "2"
        """)
    }

    func testAlignmentColonsInDelimiter() {
        let md = """
        | Left | Right |
        |:-----|------:|
        | a | b |
        """
        let (_, count) = TableConverter.convertMarkdownTables(in: md, format: .yaml)
        XCTAssertEqual(count, 1)
    }

    func testEscapedPipeInCell() {
        let md = """
        | Key | Val |
        |-----|-----|
        | a | x \\| y |
        """
        let (out, count) = TableConverter.convertMarkdownTables(in: md, format: .yaml)
        XCTAssertEqual(count, 1)
        XCTAssertEqual(out, """
        - Key: a
          Val: x | y
        """)
    }

    func testRaggedRowsArePaddedAndTruncated() {
        let md = """
        | A | B |
        |---|---|
        | 1 |
        | 2 | 3 | 4 |
        """
        let (out, count) = TableConverter.convertMarkdownTables(in: md, format: .yaml)
        XCTAssertEqual(count, 1)
        XCTAssertEqual(out, """
        - A: "1"
          B: ""
        - A: "2"
          B: "3"
        """)
    }

    // MARK: - Scalar quoting

    func testReservedAndNumericValuesAreQuoted() {
        let md = """
        | K | V |
        |---|---|
        | bool | true |
        | num | 3.14 |
        | text | hello |
        """
        let (out, _) = TableConverter.convertMarkdownTables(in: md, format: .yaml)
        XCTAssertEqual(out, """
        - K: bool
          V: "true"
        - K: num
          V: "3.14"
        - K: text
          V: hello
        """)
    }

    // MARK: - False-positive guards

    func testSetextHeadingIsNotATable() {
        let md = """
        Heading
        ---
        body text
        """
        let (out, count) = TableConverter.convertMarkdownTables(in: md, format: .yaml)
        XCTAssertEqual(count, 0)
        XCTAssertEqual(out, md)
    }

    func testDelimiterWithoutPipesIsNotATable() {
        let md = """
        | Heading |
        ---
        """
        let (out, count) = TableConverter.convertMarkdownTables(in: md, format: .yaml)
        XCTAssertEqual(count, 0)
        XCTAssertEqual(out, md)
    }

    func testHeaderAndDelimiterWithNoBodyIsNotConverted() {
        let md = """
        | A | B |
        |---|---|
        """
        let (out, count) = TableConverter.convertMarkdownTables(in: md, format: .yaml)
        XCTAssertEqual(count, 0)
        XCTAssertEqual(out, md)
    }

    func testPlainTextIsUnchanged() {
        let md = "hello\nworld"
        let (out, count) = TableConverter.convertMarkdownTables(in: md, format: .yaml)
        XCTAssertEqual(count, 0)
        XCTAssertEqual(out, md)
    }

    // MARK: - HTML

    func testHTMLTableToYAMLWrappedInPre() {
        let html = "<table><tr><th>Setting</th><th>Value</th></tr>"
            + "<tr><td>timeout</td><td>30</td></tr></table>"
        let (out, count) = TableConverter.convertHTMLTables(in: html, format: .yaml)
        XCTAssertEqual(count, 1)
        XCTAssertEqual(out, "<pre>- Setting: timeout\n  Value: \"30\"</pre>")
    }

    func testHTMLEntitiesDecodedThenReEscaped() {
        let html = "<table><tr><th>Name</th></tr><tr><td>A &amp; B</td></tr></table>"
        let (out, count) = TableConverter.convertHTMLTables(in: html, format: .yaml)
        XCTAssertEqual(count, 1)
        XCTAssertEqual(out, "<pre>- Name: A &amp; B</pre>")
    }

    func testHTMLTablePreservesSurroundingMarkup() {
        let html = "<p>before</p><table><tr><td>A</td></tr><tr><td>1</td></tr></table><p>after</p>"
        let (out, count) = TableConverter.convertHTMLTables(in: html, format: .yaml)
        XCTAssertEqual(count, 1)
        XCTAssertEqual(out, "<p>before</p><pre>- A: \"1\"</pre><p>after</p>")
    }

    func testHTMLWithoutTableIsUnchanged() {
        let html = "<p>hello</p>"
        let (out, count) = TableConverter.convertHTMLTables(in: html, format: .yaml)
        XCTAssertEqual(count, 0)
        XCTAssertEqual(out, html)
    }
}
