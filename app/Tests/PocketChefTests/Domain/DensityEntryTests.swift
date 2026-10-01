@testable import PocketChef
import XCTest

final class DensityEntryTests: XCTestCase {
    func testLookupKeyIgnoresCase() {
        XCTAssertEqual(DensityEntry.lookupKey(for: "All-Purpose Flour"), DensityEntry.lookupKey(for: "all-purpose flour"))
    }

    func testLookupKeyIgnoresSurroundingWhitespace() {
        XCTAssertEqual(DensityEntry.lookupKey(for: "  butter\n"), DensityEntry.lookupKey(for: "butter"))
    }

    /// The API canonicalizes names to NFC (issue #55), so a decomposed "é" must find the entry.
    func testLookupKeyTreatsComposedAndDecomposedFormsAsEqual() {
        let composed = "cr\u{E8}me fra\u{EE}che"
        let decomposed = "cre\u{300}me frai\u{302}che"
        XCTAssertNotEqual(Array(composed.unicodeScalars), Array(decomposed.unicodeScalars))

        XCTAssertEqual(DensityEntry.lookupKey(for: composed), DensityEntry.lookupKey(for: decomposed))
    }

    func testLookupKeyKeepsInnerWhitespace() {
        XCTAssertNotEqual(DensityEntry.lookupKey(for: "brown sugar"), DensityEntry.lookupKey(for: "brownsugar"))
    }

    func testIDIsTheLookupKey() {
        let entry = DensityEntry(ingredientName: " Honey ", gramsPerMilliliter: 1.42, lastModified: .now)

        XCTAssertEqual(entry.id, "honey")
    }
}
