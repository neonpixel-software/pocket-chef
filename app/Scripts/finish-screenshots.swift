// Turns the screenshot attachments xcresulttool exported into App Store PNGs: named after the
// screen ("1-list.png"), opaque (App Store Connect rejects an alpha channel), at an accepted size.
// Run by take-screenshots.sh.
//
// Usage: swift finish-screenshots.swift <iphone|ipad|mac> <exported attachments> <output directory>

import CoreGraphics
import Foundation
import ImageIO

let arguments = CommandLine.arguments
let platform = arguments[1]
let input = URL(fileURLWithPath: arguments[2])
let output = URL(fileURLWithPath: arguments[3])

/// The App Store sizes each platform's screenshots must have (portrait and landscape).
let sizes: [String: [CGSize]] = [
    "iphone": [CGSize(width: 1206, height: 2622), CGSize(width: 2622, height: 1206)],
    "ipad": [CGSize(width: 2064, height: 2752), CGSize(width: 2752, height: 2064)],
    "mac": [CGSize(width: 2880, height: 1800), CGSize(width: 1440, height: 900)],
]

struct Manifest: Decodable {
    struct Attachment: Decodable {
        let exportedFileName: String
        let suggestedHumanReadableName: String
    }
    let attachments: [Attachment]
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

/// The image's color at a pixel (x from the left, y from the top).
func color(of image: CGImage, x: Int, y: Int) -> CGColor {
    var pixel = [UInt8](repeating: 0, count: 4)
    let context = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.draw(image, in: CGRect(x: -x, y: y - image.height + 1, width: image.width, height: image.height))
    return CGColor(srgbRed: Double(pixel[0]) / 255, green: Double(pixel[1]) / 255, blue: Double(pixel[2]) / 255, alpha: 1)
}

let manifest = try JSONDecoder().decode([Manifest].self, from: Data(contentsOf: input.appendingPathComponent("manifest.json")))
// Only the screenshots; a failed run also attaches its UI hierarchy and a screen recording.
let attachments = manifest.flatMap(\.attachments).filter { $0.suggestedHumanReadableName.range(of: #"^[a-z]{2}-\d-"#, options: .regularExpression) != nil }
if attachments.isEmpty { fail("No screenshots in \(input.path)") }

for attachment in attachments {
    // "en-1-list_0_<UUID>.png" → "1-list.png"
    let name = attachment.suggestedHumanReadableName.components(separatedBy: "_").first!
    let screen = name.split(separator: "-", maxSplits: 1).last.map(String.init) ?? name
    guard let file = CGImageSourceCreateWithURL(input.appendingPathComponent(attachment.exportedFileName) as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(file, 0, nil) else {
        fail("Can't read \(attachment.exportedFileName)")
    }
    let size = CGSize(width: image.width, height: image.height)
    guard sizes[platform]!.contains(size) else {
        fail("\(name) is \(image.width) × \(image.height), not an App Store \(platform) size")
    }
    // Redrawn without alpha. The iOS screens are whole; the Mac window is cut out of the screen,
    // so outside its rounded corners is desktop, which each corner's nearby color replaces.
    guard let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        fail("Can't make a \(image.width) × \(image.height) image")
    }
    let inset = 24
    for (x, y) in [(inset, inset), (image.width - inset, inset), (inset, image.height - inset), (image.width - inset, image.height - inset)] {
        context.setFillColor(color(of: image, x: x, y: y))
        // The quadrant around this corner (Core Graphics counts y from the bottom).
        context.fill(CGRect(x: x < image.width / 2 ? 0 : image.width / 2, y: y < image.height / 2 ? image.height / 2 : 0,
                            width: image.width / 2, height: image.height / 2))
    }
    if platform == "mac" {
        // macOS 26 window corners: 26 pt at 1440 pt wide.
        let radius = size.width / 1440 * 26
        context.addPath(CGPath(roundedRect: CGRect(origin: .zero, size: size), cornerWidth: radius, cornerHeight: radius, transform: nil))
        context.clip()
    }
    context.draw(image, in: CGRect(origin: .zero, size: size))
    let url = output.appendingPathComponent(screen + ".png") as CFURL
    guard let opaque = context.makeImage(), let destination = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil) else {
        fail("Can't write \(screen).png")
    }
    CGImageDestinationAddImage(destination, opaque, nil)
    guard CGImageDestinationFinalize(destination) else { fail("Can't write \(screen).png") }
    print("\(platform)/\(output.lastPathComponent)/\(screen).png")
}
