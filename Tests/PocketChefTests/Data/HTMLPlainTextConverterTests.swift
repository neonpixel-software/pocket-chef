import XCTest
@testable import PocketChef

final class HTMLPlainTextConverterTests: XCTestCase {
    func testPlainTextStripsTagsAndScripts() throws {
        let html = """
        <html><head><style>body { color: red; }</style><script>alert('x')</script></head>
        <body><h1>Pancakes</h1><p>Mix 2 eggs and 1 cup flour.</p></body></html>
        """

        let text = try XCTUnwrap(HTMLPlainTextConverter.plainText(fromHTML: html))

        XCTAssertTrue(text.contains("Pancakes"))
        XCTAssertTrue(text.contains("Mix 2 eggs and 1 cup flour."))
        XCTAssertFalse(text.contains("color: red"))
        XCTAssertFalse(text.contains("alert("))
    }

    func testPlainTextReturnsNilForEmptyOrWhitespaceOnlyResult() {
        XCTAssertNil(HTMLPlainTextConverter.plainText(fromHTML: ""))
        XCTAssertNil(HTMLPlainTextConverter.plainText(fromHTML: "<html><body>   </body></html>"))
    }
}
