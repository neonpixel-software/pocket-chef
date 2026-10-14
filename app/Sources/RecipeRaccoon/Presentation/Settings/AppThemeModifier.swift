import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

extension AppTheme {
    #if os(iOS)
    /// What the app's windows override the system style with; `.unspecified` follows the device.
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }

    #elseif os(macOS)
    /// The app's appearance; nil follows the Mac.
    var appearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
    #endif
}

/// Applies the Settings theme (`AppTheme`) whenever it changes. It sets the windows' style
/// rather than SwiftUI's preferredColorScheme, so sheets, alerts and the Mac's other windows
/// (Settings, the welcome guide, About) follow too, and going back to System takes effect at once.
struct AppThemeModifier: ViewModifier {
    @AppStorage(AppTheme.storageKey) private var theme = AppTheme.system

    func body(content: Content) -> some View {
        content.onChange(of: theme, initial: true) { _, theme in Self.apply(theme) }
    }

    @MainActor
    static func apply(_ theme: AppTheme) {
        #if os(iOS)
        // Every scene's root view has this modifier, so a new iPad window gets the theme too.
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for window in scene.windows {
                window.overrideUserInterfaceStyle = theme.userInterfaceStyle
            }
        }
        #elseif os(macOS)
        NSApp.appearance = theme.appearance
        #endif
    }
}

extension View {
    /// Applies the Settings theme; see `AppThemeModifier`.
    func appTheme() -> some View {
        modifier(AppThemeModifier())
    }
}
