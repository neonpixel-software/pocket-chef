import SwiftUI

/// Branded screen header: a pink block with a subtle dot texture and an Edo SZ title,
/// replacing the plain system navigation bar title.
struct PCHeader: View {
    private static let height: CGFloat = 120
    private static let dotSpacing: CGFloat = 14
    private static let dotDiameter: CGFloat = 3
    private static let dotOpacity: Double = 0.14
    private static let titleSize: CGFloat = 34
    private static let horizontalPadding: CGFloat = 20
    private static let bottomPadding: CGFloat = 22

    let title: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
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
            Text(title)
                .font(PCFont.display(Self.titleSize))
                .foregroundStyle(PCColor.onPink)
                .padding(.horizontal, Self.horizontalPadding)
                .padding(.bottom, Self.bottomPadding)
        }
        .frame(height: Self.height)
        .ignoresSafeArea(edges: .top)
    }
}
