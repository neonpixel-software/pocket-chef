@testable import RecipeRaccoon
import ViewInspector
import XCTest

@MainActor
final class PCHeaderTests: XCTestCase {
    /// The band is one line high: a long recipe title used to run off screen, so it ends in "…"
    /// instead. The fill and every outline copy get the limit, or the outline would show where
    /// the fill is cut.
    func testTitleStaysOnOneLineInTheFillAndTheOutline() throws {
        let title = "Het beste bananenbrood recept ooit (super smeuïg en makkelijk)"
        let sut = PCHeader(title: title)

        let texts = try sut.inspect().findAll(ViewType.Text.self)
        XCTAssertEqual(texts.count, 17, "The fill and its 16 outline copies")
        for text in texts {
            XCTAssertEqual(try text.string(), title)
            XCTAssertEqual(try text.lineLimit(), 1)
        }
    }
}
