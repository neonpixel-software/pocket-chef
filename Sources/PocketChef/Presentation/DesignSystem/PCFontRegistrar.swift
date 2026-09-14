import CoreText
import Foundation

enum PCFontRegistrar {
    /// Registers bundled brand fonts (Edo SZ) so `PCFont.display` can resolve them.
    /// Safe to call multiple times — already-registered fonts are silently skipped.
    static func registerCustomFonts() {
        guard let url = Bundle.main.url(forResource: "edosz", withExtension: "ttf") else {
            assertionFailure("edosz.ttf not found in bundle — PCFont.display will fall back to the system font")
            return
        }

        var error: Unmanaged<CFError>?
        let didRegister = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        if !didRegister, let error {
            // CTFontManagerRegisterFontsForURL also reports "already registered" this way,
            // which is expected on repeated calls — assert only surfaces genuine failures in debug.
            let alreadyRegistered = (error.takeUnretainedValue() as Error as NSError).code == CTFontManagerError.alreadyRegistered.rawValue
            assert(alreadyRegistered, "Failed to register edosz.ttf: \(error.takeUnretainedValue())")
        }
    }
}
