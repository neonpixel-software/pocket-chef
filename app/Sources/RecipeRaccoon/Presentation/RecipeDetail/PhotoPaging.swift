import SwiftUI

/// The pieces the detail gallery and the full-screen viewer share: the VoiceOver label of a
/// page, a loaded page image, the page dots and the Mac's arrow buttons.
enum PhotoPaging {
    /// "Cover photo" for the first photo, "Photo 2 of 5" for the others; the form's strip uses
    /// the same labels.
    static func accessibilityLabel(at index: Int, of count: Int) -> String {
        index == 0
            ? String(localized: "Cover photo")
            : String(localized: "Photo \(index + 1) of \(count)")
    }

    /// The page index `step` pages from `currentID`, or nil past either end.
    static func index(of currentID: UUID?, steppedBy step: Int, in photos: [RecipePhoto]) -> Int? {
        let current = photos.firstIndex { $0.id == currentID } ?? 0
        let target = current + step
        return photos.indices.contains(target) ? target : nil
    }
}

/// One photo's image, read when the page appears and decoded off the main actor. Shows a photo
/// icon while the bytes aren't on this device, and tries again when a sync brings them.
struct PhotoPageImage: View {
    let photoID: UUID
    let contentMode: ContentMode
    let load: () -> Data?
    var placeholderStyle: Color = PCColor.textPrimary.opacity(0.4)
    @State private var image: Image?

    var body: some View {
        ZStack {
            if let image {
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 36))
                    .foregroundStyle(placeholderStyle)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .task(id: photoID) { image = await PhotoPageImage.image(from: load) }
        .onReceive(NotificationCenter.default.publisher(for: .recipeStoreDidChange)) { _ in
            // Only while no photo is showing (its bytes weren't here yet). A photo that's
            // showing isn't read again: its id's bytes never change once stored, and a
            // different photo (a new cover) comes with a new id, which reruns the task.
            guard image == nil else { return }
            Task { image = await PhotoPageImage.image(from: load) }
        }
    }

    /// Reads the bytes on the main actor (the store's context lives there) and decodes them off it.
    static func image(from load: () -> Data?) async -> Image? {
        guard let data = load(), let cgImage = await PhotoDecoder.decode(data) else { return nil }
        return Image(decorative: cgImage, scale: 1)
    }
}

/// One dot per page, the current one filled. Hidden from VoiceOver: each page says its
/// position itself.
struct PhotoPageDots: View {
    let count: Int
    let currentIndex: Int
    var color: Color = PCColor.pink

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? color : color.opacity(0.3))
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityHidden(true)
    }
}

#if os(macOS)
/// Previous and next buttons over a paged scroll view: a Mac has no swipe on a mouse. The
/// welcome guide uses them too, with its own labels.
struct PhotoPagingArrows: View {
    let canGoBack: Bool
    let canGoForward: Bool
    var previousLabel: LocalizedStringKey = "Previous Photo"
    var nextLabel: LocalizedStringKey = "Next Photo"
    /// ← and → as well. Off in the recipe gallery: its edit sheet's text fields need the keys.
    var usesArrowKeys = false
    let onStep: (Int) -> Void

    var body: some View {
        HStack {
            arrow("chevron.left", label: previousLabel, isEnabled: canGoBack, key: .leftArrow, step: -1)
            Spacer()
            arrow("chevron.right", label: nextLabel, isEnabled: canGoForward, key: .rightArrow, step: 1)
        }
        .padding(12)
    }

    private func arrow(_ systemImage: String, label: LocalizedStringKey, isEnabled: Bool, key: KeyEquivalent, step: Int) -> some View {
        Button { onStep(step) } label: {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .frame(width: 32, height: 32)
                .background(.regularMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(usesArrowKeys ? KeyboardShortcut(key, modifiers: []) : nil)
        .accessibilityLabel(label)
        .opacity(isEnabled ? 1 : 0)
        .disabled(!isEnabled)
    }
}
#endif
