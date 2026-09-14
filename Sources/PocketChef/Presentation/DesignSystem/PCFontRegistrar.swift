import CoreText
import Foundation

enum PCFontRegistrar {
    /// Registers bundled brand fonts (Edo SZ) so `PCFont.display` can resolve them.
    /// Safe to call multiple times — already-registered fonts are silently skipped.
    static func registerCustomFonts() {
        guard let url = Bundle.main.url(forResource: "edosz", withExtension: "ttf") else { return }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}
