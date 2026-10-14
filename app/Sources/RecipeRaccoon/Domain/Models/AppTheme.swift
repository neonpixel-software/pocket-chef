import Foundation

/// Whether the app looks light or dark. Like the cup and spoon sizes it's chosen per device in
/// Settings and never synced; until the user picks one it follows the device.
enum AppTheme: String, CaseIterable, Equatable {
    case system
    case light
    case dark

    /// The `UserDefaults` key of the Settings choice.
    static let storageKey = "appTheme"
}
