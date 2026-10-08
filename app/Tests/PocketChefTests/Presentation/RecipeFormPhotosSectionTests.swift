@testable import PocketChef
import ImageIO
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import ViewInspector
import XCTest

private struct NoOpCreateRecipeUseCase: CreateRecipeUseCase {
    func execute(_: Recipe, newPhotos _: [UUID: ProcessedPhoto]) throws {}
}

private struct NoOpUpdateRecipeUseCase: UpdateRecipeUseCase {
    func execute(_: Recipe, newPhotos _: [UUID: ProcessedPhoto]) throws {}
}

private struct NoOpFetchTagsUseCase: FetchTagsUseCase {
    func execute() throws -> [Tag] { [] }
}

private struct NoOpFindOrCreateTagUseCase: FindOrCreateTagUseCase {
    func execute(name: String) throws -> Tag {
        Tag(id: UUID(), name: name, isPreset: false)
    }
}

@MainActor
final class RecipeFormPhotosSectionTests: XCTestCase {
    private let photos = (0..<3).map { _ in RecipePhoto(id: UUID()) }

    func testTheFormHasAPhotosSection() throws {
        let sut = RecipeFormView(viewModel: makeViewModel(photos: []), onSave: { _ in })

        XCTAssertNoThrow(try sut.inspect().find(RecipeFormPhotosSection.self))
        XCTAssertNoThrow(try sut.inspect().find(text: "Add Photo"))
    }

    func testOnlyTheFirstPhotoHasTheCoverBadge() throws {
        let sut = RecipeFormPhotosSection(viewModel: makeViewModel(photos: photos))

        XCTAssertEqual(try sut.inspect().findAll(ViewType.Text.self, where: { try $0.string() == "Cover" }).count, 1)
    }

    func testPhotosAreLabeledForVoiceOver() throws {
        let sut = RecipeFormPhotosSection(viewModel: makeViewModel(photos: photos))

        let labels = try thumbnails(in: sut).map { try $0.accessibilityLabel().string() }
        XCTAssertEqual(labels, ["Cover photo", "Photo 2 of 3", "Photo 3 of 3"])
    }

    func testAccessibilityActionsArrangeThePhotos() throws {
        let viewModel = makeViewModel(photos: photos)
        let sut = RecipeFormPhotosSection(viewModel: viewModel)

        try action("Make Cover", onPhotoAt: 2, in: sut).tap()
        XCTAssertEqual(viewModel.photos.map(\.id), [photos[2].id, photos[0].id, photos[1].id])

        try action("Move Left", onPhotoAt: 1, in: sut).tap()
        XCTAssertEqual(viewModel.photos.map(\.id), [photos[0].id, photos[2].id, photos[1].id])

        try action("Move Right", onPhotoAt: 0, in: sut).tap()
        XCTAssertEqual(viewModel.photos.map(\.id), [photos[2].id, photos[0].id, photos[1].id])

        try action("Delete", onPhotoAt: 1, in: sut).tap()
        XCTAssertEqual(viewModel.photos.map(\.id), [photos[2].id, photos[1].id])
    }

    func testTheCoverCantBeMovedLeftAndTheLastPhotoCantBeMovedRight() throws {
        let sut = RecipeFormPhotosSection(viewModel: makeViewModel(photos: photos))

        XCTAssertThrowsError(try action("Make Cover", onPhotoAt: 0, in: sut))
        XCTAssertThrowsError(try action("Move Left", onPhotoAt: 0, in: sut))
        XCTAssertThrowsError(try action("Move Right", onPhotoAt: 2, in: sut))
        XCTAssertNoThrow(try action("Move Right", onPhotoAt: 0, in: sut))
    }

    func testAProcessingPhotoShowsASpinner() async throws {
        let viewModel = makeViewModel(photos: [])
        let (stream, continuation) = AsyncStream.makeStream(of: Data.self)
        let adding = Task {
            await viewModel.addPhotos([{
                for await data in stream {
                    return data
                }
                return nil
            }, ])
        }
        while !viewModel.isProcessingPhotos {
            await Task.yield()
        }
        let sut = RecipeFormPhotosSection(viewModel: viewModel)

        XCTAssertNoThrow(try sut.inspect().find(ViewType.ProgressView.self))
        XCTAssertEqual(try thumbnails(in: sut)[0].accessibilityValue().string(), "Processing")

        continuation.finish()
        await adding.value
    }

    func testThumbnailsLoadWhenShownAndAMissingOneShowsAPlaceholder() async throws {
        let viewModel = makeViewModel(photos: Array(photos[0...1]), thumbnails: [photos[0].id: try Self.pngData()])
        let sut = RecipeFormPhotosSection(viewModel: viewModel)

        let thumbnails = try sut.inspect().findAll(ViewType.ZStack.self)
        for thumbnail in thumbnails {
            try await thumbnail.callTask(id: false)
        }

        XCTAssertNoThrow(try sut.inspect().find(ViewType.Image.self, where: { try $0.actualImage().name() == "photo" }))
    }

    func testAFailedPhotoShowsTheMessage() async throws {
        let viewModel = makeViewModel(photos: [])
        await viewModel.addPhotos([{ nil }])
        let sut = RecipeFormPhotosSection(viewModel: viewModel)

        XCTAssertNoThrow(try sut.inspect().find(text: "A photo couldn't be added."))
    }

    func testPickedPhotosAreAddedToTheStrip() async throws {
        let viewModel = makeViewModel(photos: [])
        let sut = RecipeFormPhotosSection(viewModel: viewModel)

        // An identifier the photo library doesn't know: the photo fails to load and is reported.
        try sut.inspect().find(ViewType.VStack.self).callOnChange(
            oldValue: [PhotosPickerItem](),
            newValue: [PhotosPickerItem(itemIdentifier: "unknown")]
        )
        while viewModel.photoErrorMessage == nil {
            await Task.yield()
        }

        XCTAssertEqual(viewModel.photos, [])
    }

    /// A menu of Photo Library and Take Photo where there's a camera (the iOS simulators report
    /// one), otherwise a button that opens the photo picker.
    func testAddPhotoOffersTheCameraOnlyWhenThereIsOne() throws {
        let sut = RecipeFormPhotosSection(viewModel: makeViewModel(photos: []))
        let tile = try sut.inspect().find(viewWithAccessibilityIdentifier: RecipeFormPhotosSection.addPhotoAccessibilityIdentifier)

        #if os(iOS)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let menu = try tile.menu()
            XCTAssertNoThrow(try menu.find(button: "Photo Library").tap())
            XCTAssertNoThrow(try menu.find(button: "Take Photo").tap())
            return
        }
        #endif
        XCTAssertNoThrow(try tile.button().tap())
    }

    // MARK: helpers

    private func action(_ name: String, onPhotoAt index: Int, in sut: RecipeFormPhotosSection) throws -> InspectableView<ViewType.Button> {
        try thumbnails(in: sut)[index].accessibilityActions().find(button: name)
    }

    private func thumbnails(in sut: RecipeFormPhotosSection) throws -> [InspectableView<ViewType.ClassifiedView>] {
        try sut.inspect().findAll(where: {
            try $0.accessibilityIdentifier() == RecipeFormPhotosSection.photoAccessibilityIdentifier
        })
    }

    private func makeViewModel(photos: [RecipePhoto], thumbnails: [UUID: Data] = [:]) -> RecipeFormViewModel {
        let recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [], photos: photos)
        return RecipeFormViewModel(mode: .edit(recipe), dependencies: .testing(
            createRecipeUseCase: NoOpCreateRecipeUseCase(),
            updateRecipeUseCase: NoOpUpdateRecipeUseCase(),
            fetchTagsUseCase: NoOpFetchTagsUseCase(),
            findOrCreateTagUseCase: NoOpFindOrCreateTagUseCase(),
            fetchPhotoThumbnailUseCase: StubFetchPhotoThumbnailUseCase(thumbnails: thumbnails)
        ))
    }

    private static func pngData() throws -> Data {
        let context = try XCTUnwrap(CGContext(
            data: nil, width: 4, height: 4, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        let image = try XCTUnwrap(context.makeImage())
        let data = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return data as Data
    }
}
