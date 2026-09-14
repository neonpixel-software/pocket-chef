import SwiftUI

/// NeonPixel brand tokens applied to Pocket Chef. Values match the approved
/// Phase 1.4 visual identity (locked brand pink/teal plus supporting ink/cream neutrals).
enum PCColor {
    static let pink = Color(red: 255 / 255, green: 61 / 255, blue: 148 / 255)
    static let teal = Color(red: 46 / 255, green: 196 / 255, blue: 182 / 255)
    static let deepTeal = Color(red: 62 / 255, green: 122 / 255, blue: 109 / 255)
    static let ink = Color(red: 20 / 255, green: 20 / 255, blue: 31 / 255)
    static let cream = Color(red: 237 / 255, green: 228 / 255, blue: 206 / 255)
    static let darkSurface = Color(red: 31 / 255, green: 31 / 255, blue: 46 / 255)

    /// Screen background: cream in light mode, ink in dark mode.
    static let background = Color(light: cream, dark: ink)
    /// Card/row surface: white in light mode, a lighter ink in dark mode.
    static let surface = Color(light: .white, dark: darkSurface)
    /// Primary text color, always high-contrast against `background`/`surface`.
    static let textPrimary = Color(light: ink, dark: cream)
    /// Text color for content placed directly on a pink fill (buttons, badges, header titles).
    static let onPink = ink
}
