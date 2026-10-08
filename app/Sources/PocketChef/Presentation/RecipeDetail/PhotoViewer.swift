import SwiftUI

/// Which gallery page the full-screen viewer opens on.
struct PhotoViewerStart: Identifiable {
    let index: Int
    var id: Int { index }
}

/// A recipe's photos full screen on black: swipe (arrows or ← → on the Mac) between them,
/// pinch or double-tap to zoom, drag to look around a zoomed photo, Done to close.
struct PhotoViewer: View {
    static let pageAccessibilityIdentifier = "PhotoViewerPhoto"

    let photos: [RecipePhoto]
    let loadImage: (RecipePhoto) -> Data?
    @State private var currentID: UUID?
    @State private var isZoomed = false
    @Environment(\.dismiss) private var dismiss

    init(photos: [RecipePhoto], startIndex: Int, loadImage: @escaping (RecipePhoto) -> Data?) {
        self.photos = photos
        self.loadImage = loadImage
        _currentID = State(initialValue: photos.indices.contains(startIndex) ? photos[startIndex].id : photos.first?.id)
    }

    private var currentIndex: Int {
        photos.firstIndex { $0.id == currentID } ?? 0
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        ZoomablePhoto(photoID: photo.id, isZoomed: $isZoomed) { loadImage(photo) }
                            .containerRelativeFrame([.horizontal, .vertical])
                            .accessibilityElement(children: .ignore)
                            .accessibilityAddTraits(.isImage)
                            .accessibilityIdentifier(Self.pageAccessibilityIdentifier)
                            .accessibilityLabel(PhotoPaging.accessibilityLabel(at: index, of: photos.count))
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentID)
            .scrollIndicators(.hidden)
            // A drag pans a zoomed photo instead of turning the page.
            .scrollDisabled(isZoomed)
            .ignoresSafeArea()
            #if os(macOS)
            .overlay {
                if photos.count > 1 {
                    PhotoPagingArrows(
                        canGoBack: currentIndex > 0,
                        canGoForward: currentIndex < photos.count - 1,
                        onStep: { step($0) }
                    )
                }
            }
            .onKeyPress(.leftArrow) { step(-1) }
            .onKeyPress(.rightArrow) { step(1) }
            #endif
        }
        .overlay(alignment: .top) { topBar }
        .overlay(alignment: .bottom) {
            if photos.count > 1 {
                PhotoPageDots(count: photos.count, currentIndex: currentIndex, color: .white)
                    .padding(.bottom, 16)
            }
        }
        .onChange(of: currentID) { isZoomed = false }
        #if os(macOS)
        .frame(minWidth: 720, minHeight: 540)
        #endif
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button("Done") { dismiss() }
                .font(PCFont.body(16, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(.white.opacity(0.18), in: Capsule())
                .buttonStyle(.plain)
                // Esc closes the viewer on the Mac.
                .keyboardShortcut(.cancelAction)
        }
        .padding(16)
    }

    @discardableResult
    private func step(_ step: Int) -> KeyPress.Result {
        guard let target = PhotoPaging.index(of: currentID, steppedBy: step, in: photos) else { return .ignored }
        withAnimation { currentID = photos[target].id }
        return .handled
    }
}

/// Keeps a zoomed photo's pan within the page: the photo's edge can reach the page's edge, but
/// not move past it into empty space.
enum PhotoZoom {
    static func clampedOffset(_ offset: CGSize, scale: CGFloat, in size: CGSize) -> CGSize {
        let maxX = max(size.width * (scale - 1) / 2, 0)
        let maxY = max(size.height * (scale - 1) / 2, 0)
        return CGSize(
            width: min(max(offset.width, -maxX), maxX),
            height: min(max(offset.height, -maxY), maxY)
        )
    }
}

/// A photo fitted to the page that zooms up to 5× with a pinch, or 2.5× and back with a double
/// tap, and pans with a drag while zoomed.
private struct ZoomablePhoto: View {
    static let maxScale: CGFloat = 5
    static let doubleTapScale: CGFloat = 2.5

    let photoID: UUID
    @Binding var isZoomed: Bool
    let load: () -> Data?
    @State private var scale: CGFloat = 1
    @State private var scaleAtGestureStart: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var offsetAtGestureStart: CGSize = .zero
    @State private var pageSize: CGSize = .zero

    var body: some View {
        PhotoPageImage(photoID: photoID, contentMode: .fit, load: load, placeholderStyle: .white.opacity(0.5))
            .scaleEffect(scale)
            .offset(offset)
            .contentShape(Rectangle())
            .onGeometryChange(for: CGSize.self, of: \.size) { pageSize = $0 }
            .gesture(magnify)
            .gesture(pan, including: scale > 1 ? .all : .none)
            .onTapGesture(count: 2) {
                withAnimation(.snappy) { zoom(to: scale > 1 ? 1 : Self.doubleTapScale) }
            }
            // Turning the page leaves this one zoomed out for when it comes back.
            .onChange(of: isZoomed) { _, zoomed in
                if !zoomed, scale > 1 { zoom(to: 1) }
            }
    }

    private var magnify: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(scaleAtGestureStart * value.magnification, 1), Self.maxScale)
            }
            .onEnded { _ in
                withAnimation(.snappy) { zoom(to: scale) }
            }
    }

    private var pan: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = PhotoZoom.clampedOffset(
                    CGSize(
                        width: offsetAtGestureStart.width + value.translation.width,
                        height: offsetAtGestureStart.height + value.translation.height
                    ),
                    scale: scale,
                    in: pageSize
                )
            }
            .onEnded { _ in offsetAtGestureStart = offset }
    }

    private func zoom(to newScale: CGFloat) {
        scale = newScale
        scaleAtGestureStart = newScale
        // Zooming out shrinks how far the photo may be panned (to nothing at 1×).
        offset = PhotoZoom.clampedOffset(offset, scale: newScale, in: pageSize)
        offsetAtGestureStart = offset
        isZoomed = newScale > 1
    }
}
