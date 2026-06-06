import XCTest

/// Asserts the Swift app engine (`SugarStripper` + `TableConverter`) against the
/// SAME golden corpus the Go CLI runs (`internal/sugar/corpus_test.go`). This is
/// the mechanism that keeps the two implementations in parity now that they no
/// longer share code — any divergence fails here or on the Go side.
final class SugarParityCorpusTests: XCTestCase {

    private struct Case: Decodable {
        let name: String
        let input: String
        let format: String      // "markdown" | "html"
        let sugars: [String]
        let tables: String?     // "yaml" | "toml" | nil
        let expected: String
    }

    /// Resolve Tests/SugarParityCorpus.json relative to this source file so the
    /// logic-test target needs no bundled resource.
    private func corpusURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("SugarParityCorpus.json")
    }

    private func apply(_ c: Case) -> String {
        let sugars = Set(c.sugars.compactMap(Sugar.init(rawValue:)))
        let format: TableConverter.Format = (c.tables == "toml") ? .toml : .yaml

        if c.format == "html" {
            var out = SugarStripper.stripHTML(c.input, sugars: sugars).0
            if c.tables != nil {
                out = TableConverter.convertHTMLTables(in: out, format: format).0
            }
            return out
        }
        var out = SugarStripper.stripPlainText(c.input, sugars: sugars).0
        if c.tables != nil {
            out = TableConverter.convertMarkdownTables(in: out, format: format).0
        }
        return out
    }

    func testParityCorpus() throws {
        let data = try Data(contentsOf: corpusURL())
        let cases = try JSONDecoder().decode([Case].self, from: data)
        XCTAssertFalse(cases.isEmpty, "corpus is empty")

        for c in cases {
            XCTAssertEqual(apply(c), c.expected, "case \(c.name) — input: \(c.input)")
        }
    }
}
