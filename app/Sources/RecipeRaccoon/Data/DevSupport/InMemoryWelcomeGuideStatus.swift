#if DEBUG
/// A seen flag that lasts as long as the app run. UI test runs and the unit tests' host app use
/// it, so they never read or change the flag of the developer's own install.
@MainActor
final class InMemoryWelcomeGuideStatus: WelcomeGuideStatus {
    private(set) var hasSeen: Bool

    init(hasSeen: Bool) {
        self.hasSeen = hasSeen
    }

    func markSeen() {
        hasSeen = true
    }
}
#endif
