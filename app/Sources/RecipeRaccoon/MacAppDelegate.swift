#if os(macOS)
import AppKit

/// Registers the Mac app for remote notifications, so CloudKit's sync pushes reach it at once.
/// Without the registration, macOS files the app's iCloud container topic as nonwaking: APNs
/// holds the pushes, and another device's edits only arrive when the app next checks in, for
/// example on a click (PLAN 4.1, 12.4 Stage 1). iOS needs no call: the remote-notification
/// background mode in Info-iOS.plist covers it.
final class MacAppDelegate: NSObject, NSApplicationDelegate {
    private let isICloudEnabled: Bool
    private let registerForRemoteNotifications: () -> Void

    override convenience init() {
        self.init(
            isICloudEnabled: BuildConfiguration.isICloudEnabled,
            registerForRemoteNotifications: { NSApplication.shared.registerForRemoteNotifications() }
        )
    }

    init(isICloudEnabled: Bool, registerForRemoteNotifications: @escaping () -> Void) {
        self.isICloudEnabled = isICloudEnabled
        self.registerForRemoteNotifications = registerForRemoteNotifications
    }

    /// Builds without the iCloud entitlement (CI, fresh clones) have no aps-environment either,
    /// so they skip the registration.
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard isICloudEnabled else { return }
        registerForRemoteNotifications()
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        print("Failed to register for remote notifications: \(error)")
    }
}
#endif
