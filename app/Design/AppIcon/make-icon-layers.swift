// Draws the app icon's layers (the raccoon head, its chef's hat and the dot texture) and writes
// them as PNGs into AppIcon.icon/Assets. The background colour and the light/dark choice of layer
// live in AppIcon.icon/icon.json. Run app/Design/AppIcon/build.sh rather than this file.
//
// Usage: swift make-icon-layers.swift <output directory>

import AppKit

let size = 1024
let ink = "14141F", cream = "EDE4CE", pink = "FF3D94", white = "FFFFFF"

// MARK: - Geometry (a 1024 × 1024 canvas)

/// A closed path, symmetric about x = 512, from cubic segments that describe its right half
/// starting at `start` on the centre line. The left half is the mirror image, drawn back up.
func symmetricPath(_ start: (Double, Double), _ segments: [((Double, Double), (Double, Double), (Double, Double))]) -> String {
    func point(_ p: (Double, Double)) -> String { "\(p.0) \(p.1)" }
    func mirror(_ p: (Double, Double)) -> (Double, Double) { (1024 - p.0, p.1) }
    var d = "M\(point(start)) " + segments.map { "C\(point($0.0)) \(point($0.1)) \(point($0.2))" }.joined(separator: " ")
    let ends = [start] + segments.map(\.2)
    for i in segments.indices.reversed() {
        let (c1, c2, _) = segments[i]
        d += " C\(point(mirror(c2))) \(point(mirror(c1))) \(point(mirror(ends[i])))"
    }
    return d + " Z"
}

let head = symmetricPath((512, 372), [
    ((585, 368), (632, 380), (662, 402)),
    ((684, 342), (726, 292), (774, 272)), // ear
    ((796, 304), (804, 386), (774, 452)),
    ((812, 502), (842, 560), (852, 622)),
    ((840, 640), (826, 642), (812, 640)), // cheek tufts
    ((838, 660), (858, 676), (866, 690)),
    ((842, 694), (818, 690), (800, 684)),
    ((812, 700), (826, 716), (834, 732)),
    ((800, 728), (780, 718), (764, 710)),
    ((700, 752), (622, 782), (562, 816)), // jaw to snout
    ((542, 830), (526, 836), (512, 836)),
])
let innerEars = """
<path d="M688 404 C704 360 730 330 760 314 C770 346 766 394 748 432 Z"/>
<path d="M336 404 C320 360 294 330 264 314 C254 346 258 394 276 432 Z"/>
"""
let brow = symmetricPath((512, 548), [((590, 492), (708, 494), (800, 590)), ((706, 556), (604, 566), (512, 616))])
let muzzle = symmetricPath((512, 640), [((600, 636), (712, 664), (806, 706)), ((720, 734), (626, 776), (560, 806)), ((540, 818), (526, 822), (512, 822))])
let mask = symmetricPath((512, 628), [((566, 600), (690, 596), (792, 664)), ((742, 712), (656, 716), (596, 704)), ((562, 700), (538, 712), (512, 734))])
let nose = #"<ellipse cx="512" cy="796" rx="40" ry="28"/>"#
let eyes = #"<circle cx="636" cy="652" r="24"/><circle cx="388" cy="652" r="24"/>"#

let hatPuff = #"<path d="M384 344 C294 330 274 196 352 166 C362 76 456 50 512 90 C568 50 662 76 672 166 C750 196 730 330 640 344 Z"/>"#
let hatBand = #"<rect x="362" y="330" width="300" height="96" rx="22"/>"#
let hatPleats = #"<path d="M452 330 V244"/><path d="M572 330 V244"/>"#
/// The gap between the hat and the head, and between the hat's band and its puff.
let gap = 26.0

/// Wraps shapes in the canvas, placed as in the original drawing; the hat is tilted on top.
func svg(_ body: String, hat: Bool = false, stroke: Double? = nil, lineCap: Bool = false) -> String {
    var attributes = #"fill="black""#
    if let stroke { attributes += #" stroke="black" stroke-width="\#(stroke)" stroke-linejoin="round""# }
    if lineCap { attributes = #"fill="none" stroke="black" stroke-width="16" stroke-linecap="round""# }
    var content = "<g \(attributes)>\(body)</g>"
    if hat { content = #"<g transform="rotate(-8 512 400) translate(512 410) scale(1.1) translate(-512 -410)">\#(content)</g>"# }
    return #"<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024"><g transform="translate(512 540) scale(0.9) translate(-512 -480)">\#(content)</g></svg>"#
}

/// Each layer is drawn as a sequence of shapes that either add to it or cut holes into it.
enum Step { case draw(String), cut(String) }

let headSteps: [Step] = [
    .draw(svg(#"<path d="\#(head)"/>"#)),
    .cut(svg(innerEars)),
    .cut(svg(#"<path d="\#(brow)"/><path d="\#(muzzle)"/>"#)),
    .draw(svg(#"<path d="\#(mask)"/>"# + nose)),
    .cut(svg(eyes)),
    .cut(svg(hatPuff + hatBand, hat: true, stroke: gap)),
]
let hatSteps: [Step] = [
    .draw(svg(hatPuff, hat: true)),
    .cut(svg(hatBand, hat: true, stroke: gap)),
    .draw(svg(hatBand, hat: true)),
    .cut(svg(hatPleats, hat: true, lineCap: true)),
]

// MARK: - Rendering

func image(fromSVG text: String) -> NSImage {
    guard let image = NSImage(data: Data(text.utf8)) else { fatalError("Couldn't parse SVG:\n\(text)") }
    return image
}

func color(_ hex: String, alpha: Double = 1) -> NSColor {
    let value = UInt32(hex, radix: 16)!
    return NSColor(srgbRed: Double(value >> 16 & 255) / 255, green: Double(value >> 8 & 255) / 255, blue: Double(value & 255) / 255, alpha: alpha)
}

/// Renders the steps as one transparent layer filled with `hex`, and writes it as a PNG.
func writeLayer(_ steps: [Step], hex: String, alpha: Double = 1, to url: URL) throws {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let canvas = NSRect(x: 0, y: 0, width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    for step in steps {
        switch step {
        case .draw(let text): image(fromSVG: text).draw(in: canvas, from: .zero, operation: .sourceOver, fraction: 1)
        case .cut(let text): image(fromSVG: text).draw(in: canvas, from: .zero, operation: .destinationOut, fraction: 1)
        }
    }
    color(hex, alpha: alpha).set()
    canvas.fill(using: .sourceIn)
    NSGraphicsContext.restoreGraphicsState()
    // Icon Composer crops a layer to its visible pixels and centres it. Two near-invisible corner
    // pixels keep every layer at the full canvas, so the layers line up as drawn.
    let marker = color(ink, alpha: 2.0 / 255)
    rep.setColor(marker, atX: 0, y: 0)
    rep.setColor(marker, atX: size - 1, y: size - 1)
    try rep.representation(using: .png, properties: [:])!.write(to: url)
}

let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let dots = #"<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024"><defs><pattern id="d" width="64" height="64" patternUnits="userSpaceOnUse"><circle cx="32" cy="32" r="7" fill="black"/></pattern></defs><rect width="1024" height="1024" fill="url(#d)"/></svg>"#

try writeLayer(headSteps, hex: ink, to: output.appendingPathComponent("head-light.png"))
try writeLayer(headSteps, hex: cream, to: output.appendingPathComponent("head-dark.png"))
try writeLayer(hatSteps, hex: white, to: output.appendingPathComponent("hat-light.png"))
try writeLayer(hatSteps, hex: pink, to: output.appendingPathComponent("hat-dark.png"))
// The same faint dots as the in-app header (PCHeader).
try writeLayer([.draw(dots)], hex: white, alpha: 0.16, to: output.appendingPathComponent("dots.png"))
