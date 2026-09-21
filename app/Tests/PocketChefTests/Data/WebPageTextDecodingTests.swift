import XCTest
@testable import PocketChef

final class WebPageTextDecodingTests: XCTestCase {
    func testDecodeReturnsNilForEmptyData() {
        XCTAssertNil(WebPageTextDecoding.decode(Data(), declaredEncodingName: nil))
    }

    func testDecodeHandlesUTF8() {
        let data = Data("Crème brûlée".utf8)

        XCTAssertEqual(WebPageTextDecoding.decode(data, declaredEncodingName: "utf-8"), "Crème brûlée")
    }

    func testDecodeUsesDeclaredWindows1252Charset() throws {
        let data = try XCTUnwrap("Crème brûlée – 1½ cups".data(using: .windowsCP1252))

        XCTAssertEqual(WebPageTextDecoding.decode(data, declaredEncodingName: "windows-1252"), "Crème brûlée – 1½ cups")
    }

    func testDecodeSniffsMetaCharsetWhenHeaderMissing() throws {
        let html = #"<html><head><meta charset="iso-8859-1"></head><body>Jalapeño</body></html>"#
        let data = try XCTUnwrap(html.data(using: .isoLatin1))

        XCTAssertEqual(WebPageTextDecoding.decode(data, declaredEncodingName: nil), html)
    }

    func testDecodeFallsBackToLegacyEncodingForNonUTF8BytesWithNoDeclaration() throws {
        let data = try XCTUnwrap("Jalapeño".data(using: .isoLatin1))

        XCTAssertEqual(WebPageTextDecoding.decode(data, declaredEncodingName: nil), "Jalapeño")
    }

    func testDecodeIgnoresUnknownDeclaredCharset() {
        let data = Data("Pancakes".utf8)

        XCTAssertEqual(WebPageTextDecoding.decode(data, declaredEncodingName: "not-a-charset"), "Pancakes")
    }

    func testTruncatedLeavesShortTextAlone() {
        XCTAssertEqual(WebPageTextDecoding.truncated("Pancakes"), "Pancakes")
    }

    func testTruncatedCapsLongText() {
        let long = String(repeating: "a", count: WebPageTextDecoding.maxPlainTextCharacters + 500)

        XCTAssertEqual(WebPageTextDecoding.truncated(long).count, WebPageTextDecoding.maxPlainTextCharacters)
    }
}
