import SwiftUI

/// A left-to-right, top-to-bottom wrapping layout for chip-style content whose combined
/// width exceeds the available space (e.g. tag chips).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return Self.packedSize(for: sizes, maxWidth: proposal.width ?? .infinity, spacing: spacing)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let positions = Self.positions(for: sizes, maxWidth: bounds.width, spacing: spacing)
        for index in subviews.indices {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + positions[index].x, y: bounds.minY + positions[index].y),
                proposal: ProposedViewSize(sizes[index])
            )
        }
    }

    /// Top-left position for each size when wrapped left-to-right, top-to-bottom within
    /// maxWidth. Pure geometry with no SwiftUI Layout-protocol types involved, so unlike
    /// sizeThatFits/placeSubviews (which ViewInspector can't exercise — it doesn't run real
    /// SwiftUI layout) this is directly unit-testable.
    static func positions(for sizes: [CGSize], maxWidth: CGFloat, spacing: CGFloat) -> [CGPoint] {
        var result: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for size in sizes {
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            result.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return result
    }

    /// The bounding size that contains every size at its wrapped position.
    static func packedSize(for sizes: [CGSize], maxWidth: CGFloat, spacing: CGFloat) -> CGSize {
        let positions = positions(for: sizes, maxWidth: maxWidth, spacing: spacing)
        guard !positions.isEmpty else { return .zero }

        var maxX: CGFloat = 0
        var maxY: CGFloat = 0
        for (index, position) in positions.enumerated() {
            maxX = max(maxX, position.x + sizes[index].width)
            maxY = max(maxY, position.y + sizes[index].height)
        }
        return CGSize(width: maxX, height: maxY)
    }
}
