import Foundation
import Observation

/// The welcome guide (14.1): its pages, the page showing, and the seen flag. One instance per
/// app run, shared by everything that opens the guide: the list at launch, Settings and, on
/// the Mac, the Help menu.
@MainActor
@Observable
final class WelcomeGuideViewModel {
    private(set) var pages: [WelcomeGuidePage]
    /// The page showing; bound to the guide's paged scroll view.
    var currentPageID: WelcomeGuidePage.Topic?

    @ObservationIgnored private let status: WelcomeGuideStatus
    @ObservationIgnored private let isCaptureAvailable: () -> Bool

    init(status: WelcomeGuideStatus, isCaptureAvailable: @escaping () -> Bool) {
        self.status = status
        self.isCaptureAvailable = isCaptureAvailable
        pages = WelcomeGuidePage.pages(isCaptureAvailable: isCaptureAvailable())
        currentPageID = pages.first?.id
    }

    /// Whether the guide opens by itself at launch: until it has been closed once on this device.
    var showsOnLaunch: Bool {
        !status.hasSeen
    }

    var currentIndex: Int {
        pages.firstIndex { $0.id == currentPageID } ?? 0
    }

    var isOnLastPage: Bool {
        currentIndex == pages.count - 1
    }

    /// Starts from the first page each time the guide opens. Capture availability is checked
    /// again, since Apple Intelligence can be turned on while the app runs.
    func start() {
        pages = WelcomeGuidePage.pages(isCaptureAvailable: isCaptureAvailable())
        currentPageID = pages.first?.id
    }

    /// Moves `step` pages on (negative goes back); stays put past either end.
    func step(by step: Int) {
        let target = currentIndex + step
        guard pages.indices.contains(target) else { return }
        currentPageID = pages[target].id
    }

    /// The guide closed, however: Skip, Get Started, a swipe down or the window's close button.
    /// It doesn't open by itself again.
    func finish() {
        status.markSeen()
    }
}
