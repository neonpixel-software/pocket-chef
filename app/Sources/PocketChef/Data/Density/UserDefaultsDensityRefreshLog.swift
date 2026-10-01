import Foundation

/// Keeps the last refresh time in `UserDefaults`: per device, never synced.
final class UserDefaultsDensityRefreshLog: DensityRefreshLog {
    static let lastRefreshKey = "densityCacheLastRefresh"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var lastRefresh: Date? {
        defaults.object(forKey: Self.lastRefreshKey) as? Date
    }

    func recordRefresh(at date: Date) {
        defaults.set(date, forKey: Self.lastRefreshKey)
    }
}
