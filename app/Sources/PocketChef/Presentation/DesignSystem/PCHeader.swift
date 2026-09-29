import SwiftUI

/// Branded screen header: a pink block with a subtle dot texture and an Edo SZ title,
/// replacing the plain system navigation bar title.
///
/// Attach it with `.safeAreaInset(edge: .top)`. Only the pink background runs up under the
/// status and navigation bars; the header's own frame stays below them, so the inset it adds
/// is just `height` and the content starts right under the pink band.
struct PCHeader: View {
    /// Height of the band below the navigation bar, not counting the part under the bars.
    private static let height: CGFloat = 68
    private static let dotSpacing: CGFloat = 14
    private static let dotDiameter: CGFloat = 3
    private static let dotOpacity: Double = 0.14
    private static let titleSize: CGFloat = 34
    private static let titleOutlineWidth: CGFloat = 1.5
    private static let horizontalPadding: CGFloat = 20
    private static let bottomPadding: CGFloat = 22

    let title: String

    var body: some View {
        OutlinedText(text: title, font: PCFont.display(Self.titleSize), fill: .white, outline: PCColor.ink, width: Self.titleOutlineWidth)
            .padding(.horizontal, Self.horizontalPadding)
            .padding(.bottom, Self.bottomPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .frame(height: Self.height)
            // Ignoring the safe area on the background alone keeps the layout size at `height`.
            // Ignoring it on the whole view made safeAreaInset reserve the full height below the
            // bar while the pink was drawn from the top of the screen, leaving a bar-high gap (#94).
            .background {
                ZStack {
                    PCColor.pink
                    Canvas { context, size in
                        var xPos: CGFloat = 0
                        while xPos < size.width {
                            var yPos: CGFloat = 0
                            while yPos < size.height {
                                let dot = Path(ellipseIn: CGRect(x: xPos, y: yPos, width: Self.dotDiameter, height: Self.dotDiameter))
                                context.fill(dot, with: .color(.white.opacity(Self.dotOpacity)))
                                yPos += Self.dotSpacing
                            }
                            xPos += Self.dotSpacing
                        }
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
    }
}

/// White-on-pink alone is only 3.3:1, so the title gets an ink outline that keeps the glyph edges
/// legible against the pink and the white dot texture. SwiftUI has no text stroke, so the outline
/// is ink copies of the text drawn at eight offsets behind the fill.
private struct OutlinedText: View {
    let text: String
    let font: Font
    let fill: Color
    let outline: Color
    let width: CGFloat

    private static let directions: [CGPoint] = [
        CGPoint(x: -1, y: -1), CGPoint(x: 0, y: -1), CGPoint(x: 1, y: -1),
        CGPoint(x: -1, y: 0), CGPoint(x: 1, y: 0),
        CGPoint(x: -1, y: 1), CGPoint(x: 0, y: 1), CGPoint(x: 1, y: 1),
    ]

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(fill)
            .background {
                ZStack {
                    ForEach(Self.directions.indices, id: \.self) { index in
                        let direction = Self.directions[index]
                        Text(text)
                            .font(font)
                            .foregroundStyle(outline)
                            .offset(x: direction.x * width, y: direction.y * width)
                    }
                }
                .accessibilityHidden(true)
            }
    }
}
