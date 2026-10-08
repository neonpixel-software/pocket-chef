import SwiftUI

/// The photos at the top of the recipe detail, cover first: one 4:3 page per photo, with page
/// dots when there's more than one. Swiping pages on iOS; arrow buttons on the Mac. Tapping a
/// page opens it in the full-screen viewer.
struct RecipePhotoGallery: View {
    static let pageAccessibilityIdentifier = "RecipeGalleryPhoto"
    /// On a wide Mac window or iPad a full-width 4:3 page would push the recipe off screen;
    /// 560 pt keeps it 420 pt tall. An iPhone is narrower, so there it fills the width.
    static let maxWidth: CGFloat = 560

    let photos: [RecipePhoto]
    let loadImage: (RecipePhoto) -> Data?
    let onOpen: (Int) -> Void
    @State private var currentID: UUID?

    private var currentIndex: Int {
        photos.firstIndex { $0.id == currentID } ?? 0
    }

    var body: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        Button { onOpen(index) } label: {
                            PhotoPageImage(photoID: photo.id, contentMode: .fill) { loadImage(photo) }
                                .background(PCColor.surface)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .containerRelativeFrame([.horizontal, .vertical])
                        .accessibilityIdentifier(Self.pageAccessibilityIdentifier)
                        .accessibilityLabel(PhotoPaging.accessibilityLabel(at: index, of: photos.count))
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentID)
            .scrollIndicators(.hidden)
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
            #if os(macOS)
            .overlay {
                if photos.count > 1 {
                    PhotoPagingArrows(
                        canGoBack: currentIndex > 0,
                        canGoForward: currentIndex < photos.count - 1,
                        onStep: step
                    )
                }
            }
            #endif

            if photos.count > 1 {
                PhotoPageDots(count: photos.count, currentIndex: currentIndex)
            }
        }
        .frame(maxWidth: Self.maxWidth)
        // After the form saves: back to the cover when it changed or the page showing was
        // removed; otherwise stay on the page.
        .onChange(of: photos) { old, new in
            if old.first?.id != new.first?.id || !new.contains(where: { $0.id == currentID }) {
                currentID = new.first?.id
            }
        }
    }

    private func step(_ step: Int) {
        guard let target = PhotoPaging.index(of: currentID, steppedBy: step, in: photos) else { return }
        withAnimation { currentID = photos[target].id }
    }
}
