@testable import PocketChef
import XCTest

@MainActor
final class WelcomeGuideViewModelTests: XCTestCase {
    private func makeViewModel(
        status: WelcomeGuideStatus = InMemoryWelcomeGuideStatus(hasSeen: false),
        isCaptureAvailable: @escaping () -> Bool = { true }
    ) -> WelcomeGuideViewModel {
        WelcomeGuideViewModel(status: status, isCaptureAvailable: isCaptureAvailable)
    }

    func testShowsOnLaunchUntilItIsFinished() {
        let status = InMemoryWelcomeGuideStatus(hasSeen: false)
        let viewModel = makeViewModel(status: status)
        XCTAssertTrue(viewModel.showsOnLaunch)

        viewModel.finish()

        XCTAssertTrue(status.hasSeen)
        XCTAssertFalse(viewModel.showsOnLaunch)
        XCTAssertFalse(makeViewModel(status: status).showsOnLaunch, "The next launch")
    }

    func testStartsOnTheFirstOfFourPages() {
        let viewModel = makeViewModel()

        XCTAssertEqual(viewModel.pages.map(\.id), [.welcome, .addRecipe, .cook, .settings])
        XCTAssertEqual(viewModel.currentPageID, .welcome)
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertFalse(viewModel.isOnLastPage)
    }

    func testStepsThroughThePagesAndStopsAtEitherEnd() {
        let viewModel = makeViewModel()

        viewModel.step(by: -1)
        XCTAssertEqual(viewModel.currentPageID, .welcome)

        viewModel.step(by: 3)
        XCTAssertEqual(viewModel.currentPageID, .settings)
        XCTAssertTrue(viewModel.isOnLastPage)

        viewModel.step(by: 1)
        XCTAssertEqual(viewModel.currentPageID, .settings)

        viewModel.step(by: -1)
        XCTAssertEqual(viewModel.currentPageID, .cook)
    }

    /// Reopened from Settings, the guide starts over, and checks capture availability again:
    /// Apple Intelligence can be turned on while the app runs.
    func testStartGoesBackToTheFirstPageAndRechecksCapture() {
        var isAvailable = false
        let viewModel = makeViewModel(isCaptureAvailable: { isAvailable })
        XCTAssertTrue(viewModel.pages[1].items.isEmpty)
        viewModel.step(by: 2)

        isAvailable = true
        viewModel.start()

        XCTAssertEqual(viewModel.currentPageID, .welcome)
        XCTAssertEqual(viewModel.pages[1].items.count, 3)
    }

    /// The scroll view's position can be cleared mid-scroll; the guide then counts as on page 1.
    func testAMissingPositionCountsAsTheFirstPage() {
        let viewModel = makeViewModel()
        viewModel.currentPageID = nil

        XCTAssertEqual(viewModel.currentIndex, 0)
    }
}
