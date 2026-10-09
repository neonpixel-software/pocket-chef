import Foundation

/// Keeps the welcome guide's seen flag in `UserDefaults`: per device, never synced. An install
/// from before the guide has no flag, so it shows the guide once after updating.
@MainActor
final class UserDefaultsWelcomeGuideStatus: WelcomeGuideStatus {
    static let hasSeenKey = "hasSeenWelcomeGuide"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasSeen: Bool {
        defaults.bool(forKey: Self.hasSeenKey)
    }

    func markSeen() {
        defaults.set(true, forKey: Self.hasSeenKey)
    }
}
