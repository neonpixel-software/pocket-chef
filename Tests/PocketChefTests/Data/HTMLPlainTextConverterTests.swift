import XCTest
@testable import PocketChef

final class HTMLPlainTextConverterTests: XCTestCase {
    func testPlainTextStripsTagsAndScripts() async throws {
        let html = """
        <html><head><style>body { color: red; }</style><script>alert('x')</script></head>
        <body><h1>Pancakes</h1><p>Mix 2 eggs and 1 cup flour.</p></body></html>
        """

        let result = await HTMLPlainTextConverter.plainText(fromHTML: html)
        let text = try XCTUnwrap(result)

        XCTAssertTrue(text.contains("Pancakes"))
        XCTAssertTrue(text.contains("Mix 2 eggs and 1 cup flour."))
        XCTAssertFalse(text.contains("color: red"))
        XCTAssertFalse(text.contains("alert("))
    }

    func testPlainTextReturnsNilForEmptyOrWhitespaceOnlyResult() async {
        let empty = await HTMLPlainTextConverter.plainText(fromHTML: "")
        let whitespaceOnly = await HTMLPlainTextConverter.plainText(fromHTML: "<html><body>   </body></html>")

        XCTAssertNil(empty)
        XCTAssertNil(whitespaceOnly)
    }
}
