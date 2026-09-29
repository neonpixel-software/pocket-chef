import SwiftUI

/// The horizontally scrolling row of tag chips that filters the recipe list.
struct TagFilterRow: View {
    let tags: [Tag]
    let selectedTagID: UUID?
    let onSelect: (UUID?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TagChip(title: String(localized: "All"), isSelected: selectedTagID == nil) {
                    onSelect(nil)
                }
                ForEach(tags) { tag in
                    TagChip(title: tag.localizedDisplayName(), isSelected: selectedTagID == tag.id) {
                        onSelect(tag.id)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(PCColor.background)
        // macOS VoiceOver announces a scroll area and moves past it unless the user steps
        // into it, so an unnamed one hid the chips entirely (#78). The name says what's
        // inside; .contain keeps each chip its own element.
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Filter by Tag"))
    }
}
