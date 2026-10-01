import Foundation

/// When this device last refreshed the density cache successfully.
protocol DensityRefreshLog {
    var lastRefresh: Date? { get }
    func recordRefresh(at date: Date)
}
