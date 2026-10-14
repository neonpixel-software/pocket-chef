import Foundation

/// Whether this device has shown the welcome guide (14.1). Per device: a second device shows
/// the guide once too.
@MainActor
protocol WelcomeGuideStatus {
    var hasSeen: Bool { get }
    func markSeen()
}
