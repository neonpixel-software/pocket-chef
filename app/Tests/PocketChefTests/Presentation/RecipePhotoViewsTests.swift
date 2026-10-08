@testable import PocketChef
import SwiftUI
import ViewInspector
import XCTest

/// The views that show saved photos (13.3): the list row's cover, the detail gallery and the
/// full-screen viewer. Positions and paging only show in a running app, so the UI tests
/// (RecipePhotosUITests) cover those.
@MainActor
final class RecipePhotoViewsTests: XCTestCase {
    private let photos = (0..<3).map { _ in RecipePhoto(id: UUID()) }

    // MARK: Gallery

    func testGalleryLabelsEachPageForVoiceOver() throws {
        let sut = RecipePhotoGallery(photos: photos, loadImage: { _ in nil }, onOpen: { _ in })

        let labels = try pages(in: sut, identifier: RecipePhotoGallery.pageAccessibilityIdentifier)
            .map { try $0.accessibilityLabel().string() }
        XCTAssertEqual(labels, ["Cover photo", "Photo 2 of 3", "Photo 3 of 3"])
    }

    func testTappingAGalleryPageOpensItsPhoto() throws {
        var opened: Int?
        let sut = RecipePhotoGallery(photos: photos, loadImage: { _ in nil }, onOpen: { opened = $0 })

        try pages(in: sut, identifier: RecipePhotoGallery.pageAccessibilityIdentifier)[1].button().tap()

        XCTAssertEqual(opened, 1)
    }

    func testGalleryShowsPageDotsOnlyForMoreThanOnePhoto() throws {
        let several = RecipePhotoGallery(photos: photos, loadImage: { _ in nil }, onOpen: { _ in })
        let single = RecipePhotoGallery(photos: [photos[0]], loadImage: { _ in nil }, onOpen: { _ in })

        XCTAssertEqual(try several.inspect().find(PhotoPageDots.self).actualView().count, 3)
        XCTAssertThrowsError(try single.inspect().find(PhotoPageDots.self))
    }

    #if os(macOS)
    func testMacGalleryHasArrowsOnlyForMoreThanOnePhoto() throws {
        let several = RecipePhotoGallery(photos: photos, loadImage: { _ in nil }, onOpen: { _ in })
        let single = RecipePhotoGallery(photos: [photos[0]], loadImage: { _ in nil }, onOpen: { _ in })

        let arrows = try several.inspect().find(PhotoPagingArrows.self).actualView()
        XCTAssertFalse(arrows.canGoBack)
        XCTAssertTrue(arrows.canGoForward)
        XCTAssertThrowsError(try single.inspect().find(PhotoPagingArrows.self))
    }

    func testPagingArrowsStepBackAndForward() throws {
        var steps: [Int] = []
        let sut = PhotoPagingArrows(canGoBack: true, canGoForward: true, onStep: { steps.append($0) })

        try sut.inspect().find(viewWithAccessibilityLabel: "Previous Photo").button().tap()
        try sut.inspect().find(viewWithAccessibilityLabel: "Next Photo").button().tap()

        XCTAssertEqual(steps, [-1, 1])
    }
    #endif

    // MARK: Page images

    /// ViewInspector drops @State changes of a view it doesn't host, so this checks that the
    /// page reads its bytes when it appears; the UI tests check the photo on screen.
    func testPageImageReadsItsPhotoWhenItAppears() async throws {
        let data = try TestImages.png()
        var reads = 0
        let sut = PhotoPageImage(photoID: UUID(), contentMode: .fill, load: {
            reads += 1
            return data
        })

        try await sut.inspect().find(ViewType.ZStack.self).callTask(id: sut.photoID)

        XCTAssertEqual(reads, 1)
    }

    func testPageImageShowsAPlaceholderWhileTheBytesArentHere() throws {
        let sut = PhotoPageImage(photoID: UUID(), contentMode: .fit, load: { nil })

        XCTAssertNoThrow(try sut.inspect().find(ViewType.Image.self, where: { try $0.actualImage().name() == "photo" }))
    }

    func testListCoverShowsAPlaceholderWhileTheBytesArentHere() async throws {
        let sut = RecipeCoverThumbnail(photoID: UUID(), load: { nil })

        try await sut.inspect().find(ViewType.ZStack.self).callTask(id: sut.photoID)

        XCTAssertNoThrow(try sut.inspect().find(ViewType.Image.self, where: { try $0.actualImage().name() == "photo" }))
    }

    func testListCoverReadsItsPhotoWhenItAppears() async throws {
        let data = try TestImages.png()
        var reads = 0
        let sut = RecipeCoverThumbnail(photoID: UUID(), load: {
            reads += 1
            return data
        })

        try await sut.inspect().find(ViewType.ZStack.self).callTask(id: sut.photoID)

        XCTAssertEqual(reads, 1)
    }

    func testDecoderDecodesPhotoBytesAndRejectsJunk() async throws {
        let image = try await PhotoDecoder.decode(TestImages.png())
        XCTAssertEqual(image?.width, 4)
        let junk = await PhotoDecoder.decode(Data("not an image".utf8))
        XCTAssertNil(junk)
    }

    // MARK: Viewer

    func testViewerLabelsEachPhotoAndHasDone() throws {
        let sut = PhotoViewer(photos: photos, startIndex: 1, loadImage: { _ in nil })

        let labels = try pages(in: sut, identifier: PhotoViewer.pageAccessibilityIdentifier)
            .map { try $0.accessibilityLabel().string() }
        XCTAssertEqual(labels, ["Cover photo", "Photo 2 of 3", "Photo 3 of 3"])
        XCTAssertNoThrow(try sut.inspect().find(button: "Done").tap())
        XCTAssertEqual(try sut.inspect().find(PhotoPageDots.self).actualView().count, 3)
    }

    func testViewerOfOnePhotoHasNoPageDots() throws {
        let sut = PhotoViewer(photos: [photos[0]], startIndex: 5, loadImage: { _ in nil })

        XCTAssertThrowsError(try sut.inspect().find(PhotoPageDots.self))
    }

    // MARK: Detail

    func testDetailShowsTheGalleryOnlyForARecipeWithPhotos() throws {
        let withPhotos = RecipeDetailView(viewModel: makeDetailViewModel(photos: photos))
        let without = RecipeDetailView(viewModel: makeDetailViewModel(photos: []))

        XCTAssertEqual(try withPhotos.inspect().find(RecipePhotoGallery.self).actualView().photos, photos)
        XCTAssertThrowsError(try without.inspect().find(RecipePhotoGallery.self))
    }

    // MARK: helpers

    private func pages(in view: some View, identifier: String) throws -> [InspectableView<ViewType.ClassifiedView>] {
        try view.inspect().findAll(where: { try $0.accessibilityIdentifier() == identifier })
    }

    private func makeDetailViewModel(photos: [RecipePhoto]) -> RecipeDetailViewModel {
        RecipeDetailViewModel(
            recipe: Recipe(id: UUID(), title: "Salad", ingredients: [], steps: [], source: .typed, tags: [], photos: photos),
            formDependencies: .testing(
                createRecipeUseCase: NoOpCreate(),
                updateRecipeUseCase: NoOpUpdate(),
                fetchTagsUseCase: NoOpFetchTags(),
                findOrCreateTagUseCase: NoOpFindOrCreateTag()
            ),
            deleteRecipeUseCase: NoOpDelete(),
            fetchPhotoImageUseCase: StubFetchPhotoImageUseCase()
        )
    }
}

private struct NoOpCreate: CreateRecipeUseCase {
    func execute(_: Recipe, newPhotos _: [UUID: ProcessedPhoto]) throws {}
}

private struct NoOpUpdate: UpdateRecipeUseCase {
    func execute(_: Recipe, newPhotos _: [UUID: ProcessedPhoto]) throws {}
}

private struct NoOpFetchTags: FetchTagsUseCase {
    func execute() throws -> [Tag] { [] }
}

private struct NoOpFindOrCreateTag: FindOrCreateTagUseCase {
    func execute(name: String) throws -> Tag {
        Tag(id: UUID(), name: name, isPreset: false)
    }
}

private struct NoOpDelete: DeleteRecipeUseCase {
    func execute(id _: UUID) throws {}
}
