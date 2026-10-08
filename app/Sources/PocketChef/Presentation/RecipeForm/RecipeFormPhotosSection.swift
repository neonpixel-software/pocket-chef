import PhotosUI
import SwiftUI
#if os(iOS)
import AVFoundation
#endif

/// The form's photo strip: thumbnails in gallery order (the first is the cover), each with
/// Make Cover, Move Left/Right and Delete in its context menu and as accessibility actions,
/// and an Add Photo tile at the end.
struct RecipeFormPhotosSection: View {
    static let thumbnailSize: CGFloat = 80
    static let photoAccessibilityIdentifier = "RecipeFormPhoto"
    static let addPhotoAccessibilityIdentifier = "RecipeFormAddPhoto"

    let viewModel: RecipeFormViewModel
    @State private var isPresentingPicker = false
    @State private var pickerItems: [PhotosPickerItem] = []
    #if os(iOS)
    @State private var isPresentingCamera = false
    @State private var isPresentingCameraAccessAlert = false
    @Environment(\.openURL) private var openURL
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(viewModel.photos.enumerated()), id: \.element.id) { index, photo in
                        thumbnail(photo, at: index)
                    }
                    addPhotoTile
                }
            }
            .scrollClipDisabled()

            if let photoErrorMessage = viewModel.photoErrorMessage {
                Text(photoErrorMessage)
                    .font(PCFont.body(13))
                    .foregroundStyle(PCColor.pink)
            }
        }
        .photosPicker(
            isPresented: $isPresentingPicker,
            selection: $pickerItems,
            matching: .images,
            preferredItemEncoding: .compatible
        )
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            pickerItems = []
            // loadTransferable downloads an iCloud Photos original that isn't on the device.
            add(items.map { item in { try await item.loadTransferable(type: Data.self) } })
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $isPresentingCamera) {
            CameraPicker { data in add([{ data }]) }
                .ignoresSafeArea()
        }
        .alert("Camera Access Is Off", isPresented: $isPresentingCameraAccessAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("To take photos for your recipes, allow camera access in Settings.")
        }
        #endif
    }

    private func add(_ loaders: [RecipeFormViewModel.PhotoLoader]) {
        Task { await viewModel.addPhotos(loaders) }
    }

    private func thumbnail(_ photo: PhotoDraft, at index: Int) -> some View {
        let count = viewModel.photos.count
        return PhotoThumbnail(photo: photo, isCover: index == 0) { viewModel.thumbnailData(for: photo) }
            .contextMenu {
                photoActions(at: index, count: count)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier(Self.photoAccessibilityIdentifier)
            .accessibilityLabel(index == 0
                ? String(localized: "Cover photo")
                : String(localized: "Photo \(index + 1) of \(count)"))
            .accessibilityValue(photo.state == .processing ? String(localized: "Processing") : "")
            .accessibilityActions {
                photoActions(at: index, count: count)
            }
    }

    @ViewBuilder
    private func photoActions(at index: Int, count: Int) -> some View {
        if index > 0 {
            Button("Make Cover", systemImage: "star") { viewModel.makeCover(at: index) }
            Button("Move Left", systemImage: "arrow.left") { viewModel.movePhotoLeft(at: index) }
        }
        if index < count - 1 {
            Button("Move Right", systemImage: "arrow.right") { viewModel.movePhotoRight(at: index) }
        }
        Button("Delete", systemImage: "trash", role: .destructive) { viewModel.removePhoto(at: index) }
    }

    @ViewBuilder
    private var addPhotoTile: some View {
        #if os(iOS)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            Menu {
                Button("Photo Library", systemImage: "photo.on.rectangle") { isPresentingPicker = true }
                Button("Take Photo", systemImage: "camera") { takePhoto() }
            } label: {
                addPhotoLabel
            }
            .accessibilityIdentifier(Self.addPhotoAccessibilityIdentifier)
        } else {
            Button { isPresentingPicker = true } label: { addPhotoLabel }
                .buttonStyle(.plain)
                .accessibilityIdentifier(Self.addPhotoAccessibilityIdentifier)
        }
        #else
        Button { isPresentingPicker = true } label: { addPhotoLabel }
            .buttonStyle(.plain)
            .accessibilityIdentifier(Self.addPhotoAccessibilityIdentifier)
        #endif
    }

    private var addPhotoLabel: some View {
        VStack(spacing: 6) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 22, weight: .semibold))
            Text("Add Photo")
                .font(PCFont.body(12, weight: .semibold))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(PCColor.deepTeal)
        .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
        .background(PCColor.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(PCColor.deepTeal.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    #if os(iOS)
    /// The system asks for camera access the first time the camera opens; once it's been
    /// denied, the camera would only show a black screen, so point to Settings instead.
    private func takePhoto() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied, .restricted:
            isPresentingCameraAccessAlert = true
        default:
            isPresentingCamera = true
        }
    }
    #endif
}

private struct PhotoThumbnail: View {
    let photo: PhotoDraft
    let isCover: Bool
    let loadThumbnail: () -> Data?
    @State private var image: Image?

    var body: some View {
        ZStack {
            PCColor.surface
            if photo.state == .processing {
                ProgressView()
            } else if let image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                // A saved photo whose bytes CloudKit hasn't downloaded to this device yet.
                Image(systemName: "photo")
                    .font(.system(size: 22))
                    .foregroundStyle(PCColor.textPrimary.opacity(0.4))
            }
        }
        .frame(width: RecipeFormPhotosSection.thumbnailSize, height: RecipeFormPhotosSection.thumbnailSize)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .bottomLeading) {
            if isCover {
                Text("Cover")
                    .font(PCFont.body(11, weight: .bold))
                    .foregroundStyle(PCColor.ink)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(PCColor.pink, in: Capsule())
                    .padding(5)
            }
        }
        .task(id: photo.state == .processing) { reload() }
        .onReceive(NotificationCenter.default.publisher(for: .recipeStoreDidChange)) { _ in reload() }
    }

    private func reload() {
        image = loadThumbnail().flatMap(Image.init(photoData:))
    }
}
