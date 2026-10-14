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

    /// Fixed codes, not the language the tests happen to run in: on a German Mac the app runs in
    /// German. Spanish and French come back lowercase from the system.
    func testTheLanguageRowNamesEachLanguageInThatLanguage() {
        XCTAssertEqual(
            ["en", "es", "fr", "de", "nl"].map(SettingsView.languageName(for:)),
            ["English", "Español", "Français", "Deutsch", "Nederlands"]
        )
        XCTAssertEqual(SettingsView.languageName(for: "en-GB"), "English")
        XCTAssertEqual(SettingsView.languageName(for: "Base"), "English")
    }

    func testTheLanguageRowNamesOneOfTheAppsLanguages() {
        let names = ["en", "es", "fr", "de", "nl"].map(SettingsView.languageName(for:))
        XCTAssertTrue(names.contains(SettingsView.currentLanguageName), SettingsView.currentLanguageName)
    }
}
