@testable import PocketChef
import SwiftUI
import ViewInspector
import XCTest

/// The guide's buttons and pages (14.1). Paging by swipe only shows in a running app, so the
/// UI tests (WelcomeGuideUITests) cover that.
@MainActor
final class WelcomeGuideViewTests: XCTestCase {
    private func makeViewModel(status: WelcomeGuideStatus = InMemoryWelcomeGuideStatus(hasSeen: false)) -> WelcomeGuideViewModel {
        WelcomeGuideViewModel(status: status, isCaptureAvailable: { true })
    }

    func testSkipClosesTheGuide() throws {
        var closed = 0
        let sut = WelcomeGuideView(viewModel: makeViewModel()) { closed += 1 }

        try sut.inspect().find(button: "Skip").tap()

        XCTAssertEqual(closed, 1)
    }

    func testNextTurnsThePageWithoutClosing() throws {
        var closed = 0
        let viewModel = makeViewModel()
        let sut = WelcomeGuideView(viewModel: viewModel) { closed += 1 }

        try sut.inspect().find(button: "Next").tap()

        XCTAssertEqual(viewModel.currentPageID, .addRecipe)
        XCTAssertEqual(closed, 0)
    }

    func testTheLastPageHasGetStartedAndNoSkip() throws {
        var closed = 0
        let viewModel = makeViewModel()
        viewModel.step(by: 3)
        let sut = WelcomeGuideView(viewModel: viewModel) { closed += 1 }

        XCTAssertThrowsError(try sut.inspect().find(button: "Skip"))
        XCTAssertThrowsError(try sut.inspect().find(button: "Next"))
        try sut.inspect().find(button: "Get Started").tap()

        XCTAssertEqual(closed, 1)
    }

    /// A swipe down on the iPad sheet or the Mac window's close button closes the guide without
    /// a button; it doesn't open by itself again either.
    func testClosingTheGuideAnyWayMarksItSeen() throws {
        let status = InMemoryWelcomeGuideStatus(hasSeen: false)
        let sut = WelcomeGuideView(viewModel: makeViewModel(status: status)) {}

        try sut.inspect().vStack().callOnDisappear()

        XCTAssertTrue(status.hasSeen)
    }

    func testOpeningTheGuideStartsOnTheFirstPage() throws {
        let viewModel = makeViewModel()
        viewModel.step(by: 2)
        let sut = WelcomeGuideView(viewModel: viewModel) {}

        try sut.inspect().vStack().callOnAppear()

        XCTAssertEqual(viewModel.currentPageID, .welcome)
    }

    func testEachPageReadsAsOneElementThatSaysWhereItIs() throws {
        let viewModel = makeViewModel()
        let sut = WelcomeGuideView(viewModel: viewModel) {}

        let labels = try sut.inspect().findAll(WelcomeGuidePageView.self).map { try $0.accessibilityLabel().string() }

        XCTAssertEqual(labels, viewModel.pages.enumerated().map { $1.accessibilityLabel(at: $0, of: 4) })
        XCTAssertEqual(labels.first, "Welcome to Pocket Chef, A recipe box without the fluff: no ads, no life stories, just the recipe. Here's a quick tour. Page 1 of 4")
    }

    func testAPageShowsItsTitleTextPointsAndNote() throws {
        let page = WelcomeGuidePage.pages(isCaptureAvailable: true)[1]
        let sut = WelcomeGuidePageView(page: page)

        let texts = try sut.inspect().findAll(ViewType.Text.self).map { try $0.string() }

        XCTAssertEqual(texts, try [page.title, page.body] + page.items + [XCTUnwrap(page.note)])
    }

    func testAPageWithoutANoteShowsNone() throws {
        let page = WelcomeGuidePage.pages(isCaptureAvailable: true)[0]
        let sut = WelcomeGuidePageView(page: page)

        let texts = try sut.inspect().findAll(ViewType.Text.self).map { try $0.string() }

        XCTAssertEqual(texts, [page.title, page.body])
    }

    #if os(macOS)
    func testMacArrowsTurnThePagesAndHideAtTheEnds() throws {
        let viewModel = makeViewModel()
        let sut = WelcomeGuideView(viewModel: viewModel) {}

        let arrows = try sut.inspect().find(PhotoPagingArrows.self)
        XCTAssertFalse(try arrows.actualView().canGoBack)
        XCTAssertTrue(try arrows.actualView().canGoForward)
        XCTAssertTrue(try arrows.actualView().usesArrowKeys)
        try arrows.find(viewWithAccessibilityLabel: "Next Page").button().tap()

        XCTAssertEqual(viewModel.currentPageID, .addRecipe)
    }
    #endif
}
