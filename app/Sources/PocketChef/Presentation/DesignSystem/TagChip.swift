import SwiftUI

/// A small selectable capsule chip, used both for tag assignment (RecipeFormView) and
/// tag filtering (RecipeListView).
struct TagChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PCFont.body(13, weight: .semibold))
                .foregroundStyle(isSelected ? PCColor.ink : PCColor.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? PCColor.teal : PCColor.surface, in: Capsule())
        }
        .buttonStyle(.plain)
        // Selection is otherwise shown only by the fill color, which assistive tech can't see.
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
