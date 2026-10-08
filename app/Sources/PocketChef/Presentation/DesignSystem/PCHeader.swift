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

    /// Lets the UI tests find the title whatever the language (Tests/PocketChefUITests).
    static let titleAccessibilityIdentifier = "PCHeader.title"

    let title: String

    var body: some View {
        OutlinedText(text: title, font: PCFont.display(Self.titleSize), fill: .white, outline: PCColor.ink, width: Self.titleOutlineWidth)
            .accessibilityIdentifier(Self.titleAccessibilityIdentifier)
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

/// White on the base pink is 3.3:1 (AA for large text), but the white dot texture lightens it to
/// about 2.9:1, so the title gets an ink outline that keeps the glyph edges legible over the dots.
/// SwiftUI has no text stroke, so the outline is ink copies of the text drawn behind the fill at
/// evenly spaced angles on a circle of radius `width`, which keeps the stroke even on the
/// curved and slanted strokes of Edo SZ.
private struct OutlinedText: View {
    let text: String
    let font: Font
    let fill: Color
    let outline: Color
    let width: CGFloat

    /// With 16 copies the outline stays within 2% of `width` of a true circular stroke.
    private static let copyCount = 16
    private static let directions: [CGPoint] = (0..<copyCount).map { step in
        let angle = Double(step) * 2 * .pi / Double(copyCount)
        return CGPoint(x: cos(angle), y: sin(angle))
    }

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
            }
            // One element for the fill and its copies. Hiding the copies' ZStack didn't remove
            // them: the accessibility tree had the title 17 times (found by the UI tests, #98).
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(text))
    }
}

extension View {
    /// For a toolbar button over the PCHeader's pink. On iOS the bar puts it on light glass and
    /// gave it the app's pink tint: pink on pink, hard to see. Ink, like other content on pink
    /// (PCColor.onPink). The Mac draws these buttons on its own dark-pink capsules, readable as is.
    func pcHeaderToolbarButton() -> some View {
        #if os(iOS)
        tint(PCColor.onPink)
        #else
        self
        #endif
    }

    /// For a screen under a PCHeader, on iOS: the bar keeps its light look in dark mode too.
    /// Its glass otherwise turns deep pink there, and the system's own Back chevron, which no
    /// tint reaches, came out light pink on it.
    func pcHeaderBar() -> some View {
        #if os(iOS)
        toolbarColorScheme(.light, for: .navigationBar)
        #else
        self
        #endif
    }
}
