@testable import PocketChef
import SwiftUI
import XCTest
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// The launch screen's LaunchBackground asset (Info-iOS.plist) is a copy of PCColor.background's
/// cream and ink, so a cold launch goes straight to the app's background with no white or black
/// flash first (#102). An asset can't reference code, so this keeps the copy from drifting.
final class LaunchBackgroundTests: XCTestCase {
    func testLightAppearanceIsCream() throws {
        try assertLaunchBackground(dark: false, equals: PCColor.cream)
    }

    func testDarkAppearanceIsInk() throws {
        try assertLaunchBackground(dark: true, equals: PCColor.ink)
    }

    private func assertLaunchBackground(dark: Bool, equals expected: Color, file: StaticString = #filePath, line: UInt = #line) throws {
        let asset = try XCTUnwrap(launchBackgroundComponents(dark: dark), "The LaunchBackground color asset is missing", file: file, line: line)
        let code = try XCTUnwrap(srgbComponents(of: expected), file: file, line: line)
        for (assetValue, codeValue) in zip(asset, code) {
            XCTAssertEqual(assetValue, codeValue, accuracy: 0.5 / 255, "LaunchBackground \(asset) ≠ PCColor \(code)", file: file, line: line)
        }
    }

    /// The asset's red, green, blue and alpha in sRGB for the light or dark appearance.
    private func launchBackgroundComponents(dark: Bool) -> [CGFloat]? {
        #if os(iOS)
        let traits = UITraitCollection(userInterfaceStyle: dark ? .dark : .light)
        // The named color is dynamic; reading it without resolving gives the light variant.
        return UIColor(named: "LaunchBackground", in: .main, compatibleWith: traits).flatMap { rgba($0.resolvedColor(with: traits)) }
        #elseif os(macOS)
        guard let color = NSColor(named: "LaunchBackground"), let appearance = NSAppearance(named: dark ? .darkAqua : .aqua) else { return nil }
        var components: [CGFloat]?
        appearance.performAsCurrentDrawingAppearance { components = rgba(color) }
        return components
        #endif
    }

    private func srgbComponents(of color: Color) -> [CGFloat]? {
        #if os(iOS)
        rgba(UIColor(color))
        #elseif os(macOS)
        rgba(NSColor(color))
        #endif
    }

    #if os(iOS)
    private func rgba(_ color: UIColor) -> [CGFloat]? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return [red, green, blue, alpha]
    }

    #elseif os(macOS)
    private func rgba(_ color: NSColor) -> [CGFloat]? {
        guard let srgb = color.usingColorSpace(.sRGB) else { return nil }
        return [srgb.redComponent, srgb.greenComponent, srgb.blueComponent, srgb.alphaComponent]
    }
    #endif
}
