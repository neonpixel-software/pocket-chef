@testable import RecipeRaccoon
import SwiftUI
import XCTest

/// The Settings theme: what each choice applies, and the language row's name.
@MainActor
final class AppThemeTests: XCTestCase {
    func testTheThemeIsStoredUnderItsOwnKey() {
        XCTAssertEqual(AppTheme.storageKey, "appTheme")
        XCTAssertEqual(AppTheme.allCases.map(\.rawValue), ["system", "light", "dark"])
    }

    #if os(macOS)
    func testEachThemeSetsTheAppsAppearance() {
        let original = NSApp.appearance
        defer { NSApp.appearance = original }

        XCTAssertNil(AppTheme.system.appearance)
        XCTAssertEqual(AppTheme.light.appearance?.name, .aqua)
        XCTAssertEqual(AppTheme.dark.appearance?.name, .darkAqua)

        AppThemeModifier.apply(.dark)
        XCTAssertEqual(NSApp.appearance?.name, .darkAqua)
        AppThemeModifier.apply(.system)
        XCTAssertNil(NSApp.appearance)
    }
    #else
    func testEachThemeOverridesTheWindowsStyle() {
        XCTAssertEqual(AppTheme.system.userInterfaceStyle, .unspecified)
        XCTAssertEqual(AppTheme.light.userInterfaceStyle, .light)
        XCTAssertEqual(AppTheme.dark.userInterfaceStyle, .dark)
    }
    #endif

    /// The tests run in English, so the row names the language as English does.
    func testTheLanguageRowNamesTheLanguageTheAppRunsIn() {
        XCTAssertEqual(SettingsView.currentLanguageName, "English")
    }
}
