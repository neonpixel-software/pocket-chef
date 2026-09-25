@testable import PocketChef
import ViewInspector
import XCTest

@MainActor
final class TagChipTests: XCTestCase {
    /// The chip's title is its accessible name (issue #78). ViewInspector can't read
    /// accessibility traits, so the isSelected trait was checked in the running app instead.
    func testChipIsFoundAsAButtonByItsTitle() throws {
        let sut = TagChip(title: "Breakfast", isSelected: true, action: {})

        XCTAssertNoThrow(try sut.inspect().find(button: "Breakfast"))
    }

    func testTappingChipCallsAction() throws {
        nonisolated(unsafe) var tapped = false
        let sut = TagChip(title: "Breakfast", isSelected: false, action: { tapped = true })

        try sut.inspect().find(button: "Breakfast").tap()

        XCTAssertTrue(tapped)
    }
}
