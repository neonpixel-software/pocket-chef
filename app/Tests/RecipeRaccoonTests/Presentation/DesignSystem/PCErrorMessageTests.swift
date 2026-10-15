@testable import RecipeRaccoon
import ViewInspector
import XCTest

@MainActor
final class PCErrorMessageTests: XCTestCase {
    func testShowsTheMessageWithAWarningIcon() throws {
        let sut = PCErrorMessage("A photo couldn't be added.")

        XCTAssertNoThrow(try sut.inspect().find(text: "A photo couldn't be added."))
        XCTAssertEqual(try sut.inspect().find(ViewType.Image.self).actualImage().name(), "exclamationmark.triangle.fill")
    }
}
