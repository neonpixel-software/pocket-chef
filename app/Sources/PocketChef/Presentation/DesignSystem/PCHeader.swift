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
    private static let horizontalPadding: CGFloat = 20
    private static let bottomPadding: CGFloat = 22

    let title: String

    var body: some View {
        Text(title)
            .font(PCFont.display(Self.titleSize))
            .foregroundStyle(PCColor.onPink)
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
