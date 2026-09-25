@testable import PocketChef
import XCTest

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

    func testDecodeMapsDeclaredISO88591ToWindows1252ForSmartQuotes() throws {
        // U+2019 encodes to byte 0x92 in CP1252 — a C1 control character in Latin-1, which maps
        // every byte and would otherwise win outright since it's tried before windows-1252.
        let data = try XCTUnwrap("Grandma’s Pancakes".data(using: .windowsCP1252))

        XCTAssertEqual(WebPageTextDecoding.decode(data, declaredEncodingName: "iso-8859-1"), "Grandma’s Pancakes")
    }

    func testTruncatedLeavesShortTextAlone() {
        XCTAssertEqual(WebPageTextDecoding.truncated("Pancakes"), "Pancakes")
    }

    func testPlainTextCapLeavesRoomInTheModelsContextWindow() {
        // The on-device model's context is 4,096 tokens shared by instructions (~50), the
        // CapturedRecipeSchema (~350) and the generated recipe (up to ~1,000). Page text measured
        // as low as ~2.7 characters per token, so the cap must stay at or below ~6,000 (issue #74).
        XCTAssertLessThanOrEqual(WebPageTextDecoding.maxPlainTextCharacters, 6000)
    }

    func testTruncatedCapsLongText() {
        let long = String(repeating: "a", count: WebPageTextDecoding.maxPlainTextCharacters + 500)

        XCTAssertEqual(WebPageTextDecoding.truncated(long).count, WebPageTextDecoding.maxPlainTextCharacters)
    }

    func testAppendAllowsBytesUpToTheCap() throws {
        var buffer = Data()

        for byte in repeatElement(UInt8(ascii: "a"), count: WebPageTextDecoding.maxDownloadBytes) {
            try WebPageTextDecoding.append(byte, to: &buffer)
        }

        XCTAssertEqual(buffer.count, WebPageTextDecoding.maxDownloadBytes)
    }

    func testAppendThrowsTooLargeOnceCapIsExceeded() {
        var buffer = Data(repeating: UInt8(ascii: "a"), count: WebPageTextDecoding.maxDownloadBytes)

        do {
            try WebPageTextDecoding.append(UInt8(ascii: "a"), to: &buffer)
            XCTFail("Expected WebPageFetchError.tooLarge")
        } catch WebPageFetchError.tooLarge {
            // Expected.
        } catch {
            XCTFail("Expected WebPageFetchError.tooLarge, got \(error)")
        }
    }
}
