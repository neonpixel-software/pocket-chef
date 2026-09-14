import SwiftUI

/// Branded screen header: a pink block with a subtle dot texture and an Edo SZ title,
/// replacing the plain system navigation bar title.
struct PCHeader: View {
    let title: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PCColor.pink
            Canvas { context, size in
                let spacing: CGFloat = 14
                var x: CGFloat = 0
                while x < size.width {
                    var y: CGFloat = 0
                    while y < size.height {
                        let dot = Path(ellipseIn: CGRect(x: x, y: y, width: 3, height: 3))
                        context.fill(dot, with: .color(.white.opacity(0.14)))
                        y += spacing
                    }
                    x += spacing
                }
            }
            Text(title)
                .font(PCFont.display(34))
                .foregroundStyle(PCColor.onPink)
                .padding(.horizontal, 20)
                .padding(.bottom, 22)
        }
        .frame(height: 120)
        .ignoresSafeArea(edges: .top)
    }
}
