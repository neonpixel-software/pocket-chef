import SwiftUI

/// NeonPixel brand tokens applied to Recipe Raccoon. Values match the approved
/// Phase 1.4 visual identity (locked brand pink/teal plus supporting ink/cream neutrals; the light background
/// moved from cream to a neutral pale gray on 2026-10-15).
enum PCColor {
    static let pink = Color(red: 1.0, green: 61 / 255, blue: 148 / 255)
    static let teal = Color(red: 46 / 255, green: 196 / 255, blue: 182 / 255)
    static let deepTeal = Color(red: 62 / 255, green: 122 / 255, blue: 109 / 255)
    static let ink = Color(red: 20 / 255, green: 20 / 255, blue: 31 / 255)
    static let cream = Color(red: 237 / 255, green: 228 / 255, blue: 206 / 255)
    static let paleGray = Color(red: 242 / 255, green: 242 / 255, blue: 247 / 255)
    static let darkSurface = Color(red: 31 / 255, green: 31 / 255, blue: 46 / 255)

    /// Screen background: pale gray in light mode, ink in dark mode.
    static let background = Color(light: paleGray, dark: ink)
    /// Card/row surface: white in light mode, a lighter ink in dark mode.
    static let surface = Color(light: .white, dark: darkSurface)
    /// Primary text color, always high-contrast against `background`/`surface`.
    static let textPrimary = Color(light: ink, dark: cream)
    /// Text color for content placed directly on a pink fill (buttons, badges).
    /// `PCHeader` titles are the exception: white with an ink outline.
    static let onPink = ink
}
