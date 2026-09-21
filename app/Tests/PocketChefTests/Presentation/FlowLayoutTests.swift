@testable import PocketChef
import XCTest

final class FlowLayoutTests: XCTestCase {
    func testPositionsForEmptyInputIsEmpty() {
        XCTAssertEqual(FlowLayout.positions(for: [], maxWidth: 100, spacing: 8), [])
    }

    func testSingleItemIsPositionedAtOrigin() {
        let positions = FlowLayout.positions(for: [CGSize(width: 40, height: 20)], maxWidth: 100, spacing: 8)

        XCTAssertEqual(positions, [.zero])
    }

    func testItemsThatFitStayOnTheSameRow() {
        let sizes = [CGSize(width: 40, height: 20), CGSize(width: 30, height: 20)]

        let positions = FlowLayout.positions(for: sizes, maxWidth: 100, spacing: 8)

        XCTAssertEqual(positions, [CGPoint(x: 0, y: 0), CGPoint(x: 48, y: 0)]) // 40 + spacing(8)
    }

    func testItemThatDoesNotFitWrapsToNextRow() {
        let sizes = [CGSize(width: 60, height: 20), CGSize(width: 60, height: 30)]

        let positions = FlowLayout.positions(for: sizes, maxWidth: 100, spacing: 8)

        XCTAssertEqual(positions[0], .zero)
        XCTAssertEqual(positions[1], CGPoint(x: 0, y: 28)) // previous row height(20) + spacing(8)
    }

    func testRowHeightUsesTheTallestItemInThatRow() {
        let sizes = [
            CGSize(width: 30, height: 40), // tall
            CGSize(width: 20, height: 20), // same row (30+8+20=58 <= 70), shorter
            CGSize(width: 60, height: 20), // wraps — row 1's height should be based on the tall item
        ]

        let positions = FlowLayout.positions(for: sizes, maxWidth: 70, spacing: 8)

        XCTAssertEqual(positions[1], CGPoint(x: 38, y: 0)) // confirms item 1 shared row 1 with item 0
        XCTAssertEqual(positions[2].y, 48) // 40 + spacing(8), not 20 + 8
    }

    func testPackedSizeMatchesBoundingBoxOfWrappedContent() {
        let sizes = [CGSize(width: 60, height: 20), CGSize(width: 60, height: 30)]

        let size = FlowLayout.packedSize(for: sizes, maxWidth: 100, spacing: 8)

        // Row 1: width 60, height 20. Row 2 (wrapped): width 60 at y=28, height 30.
        XCTAssertEqual(size, CGSize(width: 60, height: 58))
    }

    func testPackedSizeForEmptyInputIsZero() {
        XCTAssertEqual(FlowLayout.packedSize(for: [], maxWidth: 100, spacing: 8), .zero)
    }
}
