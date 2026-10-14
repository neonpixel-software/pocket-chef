import XCTest

/// An 8-bit sRGB color read from a screenshot.
struct RGB: CustomStringConvertible {
    let red: Int
    let green: Int
    let blue: Int

    var description: String {
        "(\(red), \(green), \(blue))"
    }
}

extension XCTestCase {
    /// The sRGB color of the window's screenshot at a point in window coordinates. On a Mac,
    /// XCTest's screenshots need the Screen Recording permission (see the README).
    @MainActor
    func pixel(at point: CGPoint, in window: XCUIElement) -> RGB {
        let image = window.screenshot().image
        #if os(macOS)
        var rect = CGRect(origin: .zero, size: image.size)
        let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
        #else
        let cgImage = image.cgImage
        #endif
        guard let cgImage, let space = CGColorSpace(name: CGColorSpace.sRGB) else {
            XCTFail("Couldn't read the window's screenshot")
            return RGB(red: 0, green: 0, blue: 0)
        }
        let scale = CGFloat(cgImage.width) / window.frame.width
        var rgba = [UInt8](repeating: 0, count: 4)
        rgba.withUnsafeMutableBytes { buffer in
            let context = CGContext(
                data: buffer.baseAddress,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
            // Core Graphics counts y from the bottom: shift the image so the pixel lands on (0, 0).
            let height = CGFloat(cgImage.height)
            context?.draw(cgImage, in: CGRect(
                x: -(point.x * scale).rounded(.down),
                y: -(height - 1 - (point.y * scale).rounded(.down)),
                width: CGFloat(cgImage.width),
                height: height
            ))
        }
        return RGB(red: Int(rgba[0]), green: Int(rgba[1]), blue: Int(rgba[2]))
    }

    /// The color at the center of an element, read from the app's window.
    @MainActor
    func pixel(atCenterOf element: XCUIElement, in app: XCUIApplication) -> RGB {
        let window = app.windows.firstMatch
        let point = CGPoint(x: element.frame.midX - window.frame.minX, y: element.frame.midY - window.frame.minY)
        return pixel(at: point, in: window)
    }
}
