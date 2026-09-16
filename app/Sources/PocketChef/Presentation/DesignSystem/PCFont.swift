import SwiftUI

/// Display font is Edo SZ (the NeonPixel logo/heading face) — titles only, never body copy.
/// Body font is Helvetica, per the NeonPixel style guide.
enum PCFont {
    static func display(_ size: CGFloat) -> Font {
        .custom("Edo SZ", size: size)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Helvetica Neue", size: size).weight(weight)
    }
}
