import Foundation

/// String(localized:locale:)'s `locale` parameter affects formatting (plurals, numbers) within
/// the resolved string, not which translation gets selected — selection follows
/// Bundle.preferredLocalizations, which reflects the process's actual system language and can't
/// be forced to a different one at runtime. So tests that need to pin a specific translated
/// language read the compiled String Catalog output directly from each language's .lproj
/// bundle instead, via the same NSBundle API SwiftUI's own localization machinery uses.
enum LocalizationTestHelper {
    /// Returns the translated value for `key` in the given language. Note:
    /// Bundle.localizedString(forKey:) falls back to returning `key` itself when the catalog has
    /// no entry for it — callers should only treat that as "missing" when the expected
    /// translation is known to differ from the English source text (some words are identical
    /// across languages, e.g. "Snack" in Dutch, so equality alone isn't a reliable missing-entry
    /// signal here).
    static func translatedString(_ key: String, languageCode: String) -> String? {
        guard let lprojPath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: lprojPath) else {
            return nil
        }
        return bundle.localizedString(forKey: key, value: nil, table: "Localizable")
    }

    /// Whether the language's catalog has an entry for `key`, for words that are the same in
    /// English and that language. A missing key returns the `value` passed in, which no
    /// translation is.
    static func hasEntry(_ key: String, languageCode: String) -> Bool {
        guard let lprojPath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: lprojPath) else {
            return false
        }
        let missing = "\u{0}missing"
        return bundle.localizedString(forKey: key, value: missing, table: "Localizable") != missing
    }
}
