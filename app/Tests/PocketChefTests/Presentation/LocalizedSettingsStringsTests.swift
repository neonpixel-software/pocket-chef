@testable import PocketChef
import XCTest

/// Every string the settings screen shows (Phase 4.1) must have a catalog entry in each
/// translated language. The translations themselves still need the fluent-speaker pass (#65).
final class LocalizedSettingsStringsTests: XCTestCase {
    private let keys = [
        "Settings",
        "Done",
        "Storage",
        "Store Recipes",
        "On This Device",
        "Moving your recipes…",
        "With iCloud, your recipes sync to your other devices signed in to the same account. Switching back to this device keeps a copy of every recipe here and stops syncing.",
        "iCloud sync isn't available in this build.",
        "Sign in to iCloud on this device to sync your recipes.",
        "iCloud is restricted on this device, so recipes can't sync.",
        "iCloud is temporarily unavailable. Try again in a moment.",
        "Couldn't reach iCloud. Check your connection and try again.",
        "Couldn't change where recipes are stored. Try again.",
    ]

    /// A missing entry falls back to the English key, and every key here differs from its
    /// translation in all four languages, so equality means the entry is missing.
    func testEverySettingsStringIsTranslated() {
        for key in keys {
            for languageCode in ["es", "fr", "de", "nl"] {
                let translated = LocalizationTestHelper.translatedString(key, languageCode: languageCode)
                XCTAssertNotNil(translated, "\(key) in \(languageCode)")
                XCTAssertNotEqual(translated, key, "\(key) in \(languageCode)")
            }
        }
    }

    func testSpotCheckGermanStorageLabels() {
        XCTAssertEqual(LocalizationTestHelper.translatedString("On This Device", languageCode: "de"), "Auf diesem Gerät")
        XCTAssertEqual(LocalizationTestHelper.translatedString("Settings", languageCode: "de"), "Einstellungen")
    }
}
