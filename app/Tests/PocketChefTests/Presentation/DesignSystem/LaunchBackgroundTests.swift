#if os(iOS)
@testable import PocketChef
import SwiftUI
import UIKit
import XCTest

/// The launch screen's LaunchBackground asset (Info-iOS.plist) is a copy of PCColor.background's
/// cream and ink, so a cold launch goes straight to the app's background with no white or black
/// flash first (#102). An asset can't reference code, so this keeps the copy from drifting.
///
/// iOS only: UILaunchScreen is an iOS and iPadOS key, and a macOS app has no launch screen, so
/// nothing on the Mac reads the asset.
final class LaunchBackgroundTests: XCTestCase {
    func testLightAppearanceIsCream() throws {
        try assertLaunchBackground(.light, equals: PCColor.cream)
    }

    func testDarkAppearanceIsInk() throws {
        try assertLaunchBackground(.dark, equals: PCColor.ink)
    }

    private func assertLaunchBackground(
        _ style: UIUserInterfaceStyle,
        equals expected: Color,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let traits = UITraitCollection(userInterfaceStyle: style)
        let named = try XCTUnwrap(
            UIColor(named: "LaunchBackground", in: .main, compatibleWith: traits),
            "The LaunchBackground color asset is missing",
            file: file,
            line: line
        )
        // The named color is dynamic; reading it without resolving gives the light variant.
        let asset = try XCTUnwrap(rgba(named.resolvedColor(with: traits)), file: file, line: line)
        let code = try XCTUnwrap(rgba(UIColor(expected)), file: file, line: line)
        for (assetValue, codeValue) in zip(asset, code) {
            XCTAssertEqual(assetValue, codeValue, accuracy: 0.5 / 255, "LaunchBackground \(asset) ≠ PCColor \(code)", file: file, line: line)
        }
    }

    /// Red, green, blue and alpha in sRGB.
    private func rgba(_ color: UIColor) -> [CGFloat]? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return [red, green, blue, alpha]
    }
}
#endif
