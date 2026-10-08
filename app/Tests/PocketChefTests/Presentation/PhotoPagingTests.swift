@testable import PocketChef
import XCTest

final class PhotoPagingTests: XCTestCase {
    private let photos = (0..<3).map { _ in RecipePhoto(id: UUID()) }

    func testAccessibilityLabelNamesTheCoverAndCountsTheOthers() {
        XCTAssertEqual(PhotoPaging.accessibilityLabel(at: 0, of: 3), "Cover photo")
        XCTAssertEqual(PhotoPaging.accessibilityLabel(at: 1, of: 3), "Photo 2 of 3")
        XCTAssertEqual(PhotoPaging.accessibilityLabel(at: 2, of: 3), "Photo 3 of 3")
    }

    func testIndexStepsFromTheCurrentPhotoWithinTheGallery() {
        XCTAssertEqual(PhotoPaging.index(of: photos[1].id, steppedBy: 1, in: photos), 2)
        XCTAssertEqual(PhotoPaging.index(of: photos[1].id, steppedBy: -1, in: photos), 0)
        XCTAssertNil(PhotoPaging.index(of: photos[2].id, steppedBy: 1, in: photos))
        XCTAssertNil(PhotoPaging.index(of: photos[0].id, steppedBy: -1, in: photos))
    }

    /// Before the scroll view reports a position, or after the current photo was removed, the
    /// gallery is on its first page.
    func testIndexStartsFromTheFirstPhotoWithoutAKnownCurrentOne() {
        XCTAssertEqual(PhotoPaging.index(of: nil, steppedBy: 1, in: photos), 1)
        XCTAssertEqual(PhotoPaging.index(of: UUID(), steppedBy: 1, in: photos), 1)
    }

    func testPanStaysWithinTheZoomedPhoto() {
        let page = CGSize(width: 400, height: 300)

        // At 2× the photo is 800 × 600, so it can move 200 pt sideways and 150 pt up or down.
        XCTAssertEqual(PhotoZoom.clampedOffset(CGSize(width: 500, height: -500), scale: 2, in: page), CGSize(width: 200, height: -150))
        XCTAssertEqual(PhotoZoom.clampedOffset(CGSize(width: -50, height: 20), scale: 2, in: page), CGSize(width: -50, height: 20))
        XCTAssertEqual(PhotoZoom.clampedOffset(CGSize(width: 80, height: 80), scale: 1, in: page), .zero)
    }
}
