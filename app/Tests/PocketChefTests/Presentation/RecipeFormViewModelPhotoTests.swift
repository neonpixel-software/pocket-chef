@testable import PocketChef
import XCTest

private final class RecordingCreateRecipeUseCase: CreateRecipeUseCase {
    private(set) var calls: [(recipe: Recipe, newPhotos: [UUID: ProcessedPhoto])] = []

    func execute(_ recipe: Recipe, newPhotos: [UUID: ProcessedPhoto]) throws {
        calls.append((recipe, newPhotos))
    }
}

private final class RecordingUpdateRecipeUseCase: UpdateRecipeUseCase {
    private(set) var calls: [(recipe: Recipe, newPhotos: [UUID: ProcessedPhoto])] = []

    func execute(_ recipe: Recipe, newPhotos: [UUID: ProcessedPhoto]) throws {
        calls.append((recipe, newPhotos))
    }
}

private struct NoOpFetchTagsUseCase: FetchTagsUseCase {
    func execute() throws -> [Tag] { [] }
}

private struct NoOpFindOrCreateTagUseCase: FindOrCreateTagUseCase {
    func execute(name: String) throws -> Tag {
        Tag(id: UUID(), name: name, isPreset: false)
    }
}

private struct LoadFailure: Error {}

/// The Photos section of the form (PLAN 13.2).
@MainActor
final class RecipeFormViewModelPhotoTests: XCTestCase {
    private let createUseCase = RecordingCreateRecipeUseCase()
    private let updateUseCase = RecordingUpdateRecipeUseCase()

    // MARK: hydrating and saving

    func testEditModeShowsTheRecipesPhotosAsStoredInGalleryOrder() {
        let photos = [RecipePhoto(id: UUID()), RecipePhoto(id: UUID())]
        let viewModel = makeViewModel(mode: .edit(makeRecipe(photos: photos)))

        XCTAssertEqual(viewModel.photos.map(\.id), photos.map(\.id))
        XCTAssertEqual(viewModel.photos.map(\.state), [.stored, .stored])
    }

    func testSavingAnUntouchedEditKeepsThePhotosWithoutNewBytes() throws {
        let photos = [RecipePhoto(id: UUID()), RecipePhoto(id: UUID())]
        let viewModel = makeViewModel(mode: .edit(makeRecipe(photos: photos)))

        viewModel.save()

        let call = try XCTUnwrap(updateUseCase.calls.first)
        XCTAssertEqual(call.recipe.photos, photos)
        XCTAssertEqual(call.newPhotos, [:])
    }

    func testAddedPhotosAreSavedInOrderWithTheirProcessedBytes() async throws {
        let stored = RecipePhoto(id: UUID())
        let viewModel = makeViewModel(mode: .edit(makeRecipe(photos: [stored])))

        await viewModel.addPhotos([loader("a"), loader("b")])
        viewModel.save()

        let call = try XCTUnwrap(updateUseCase.calls.first)
        let added = viewModel.photos.dropFirst().map(\.id)
        XCTAssertEqual(call.recipe.photos.map(\.id), [stored.id] + added)
        XCTAssertEqual(call.newPhotos, [
            added[0]: FakePhotoProcessor.processed(Data("a".utf8)),
            added[1]: FakePhotoProcessor.processed(Data("b".utf8)),
        ])
    }

    func testCreateModeSavesAddedPhotosThroughTheCreateUseCase() async throws {
        let viewModel = makeViewModel(mode: .create)
        viewModel.title = "Pancakes"

        await viewModel.addPhotos([loader("a")])
        viewModel.save()

        let call = try XCTUnwrap(createUseCase.calls.first)
        XCTAssertEqual(call.recipe.photos.map(\.id), viewModel.photos.map(\.id))
        XCTAssertEqual(call.newPhotos.values.first, FakePhotoProcessor.processed(Data("a".utf8)))
        XCTAssertTrue(updateUseCase.calls.isEmpty)
    }

    func testPhotosAddedButNeverSavedAreNotStored() async {
        let viewModel = makeViewModel(mode: .create)
        viewModel.title = "Pancakes"

        await viewModel.addPhotos([loader("a")])

        // Cancel dismisses the form without calling save().
        XCTAssertTrue(createUseCase.calls.isEmpty)
        XCTAssertTrue(updateUseCase.calls.isEmpty)
    }

    func testRemovedPhotosAreLeftOutOfTheSave() async throws {
        let photos = [RecipePhoto(id: UUID()), RecipePhoto(id: UUID())]
        let viewModel = makeViewModel(mode: .edit(makeRecipe(photos: photos)))
        await viewModel.addPhotos([loader("a")])

        viewModel.removePhoto(at: 2)
        viewModel.removePhoto(at: 0)
        viewModel.save()

        let call = try XCTUnwrap(updateUseCase.calls.first)
        XCTAssertEqual(call.recipe.photos, [photos[1]])
        XCTAssertEqual(call.newPhotos, [:])
    }

    // MARK: processing

    func testSaveIsDisabledWhileAPhotoIsProcessing() async {
        let viewModel = makeViewModel(mode: .create)
        viewModel.title = "Pancakes"
        let (stream, continuation) = AsyncStream.makeStream(of: Data.self)
        let adding = Task { await viewModel.addPhotos([loader(waitingFor: stream)]) }

        while !viewModel.isProcessingPhotos {
            await Task.yield()
        }
        XCTAssertEqual(viewModel.photos.map(\.state), [.processing])
        XCTAssertFalse(viewModel.canSave)
        XCTAssertNil(viewModel.thumbnailData(for: viewModel.photos[0]))

        continuation.yield(Data("a".utf8))
        await adding.value

        XCTAssertEqual(viewModel.photos.map(\.state), [.processed(FakePhotoProcessor.processed(Data("a".utf8)))])
        XCTAssertTrue(viewModel.canSave)
    }

    func testAPhotoDeletedWhileProcessingStaysDeleted() async {
        let viewModel = makeViewModel(mode: .create)
        let (stream, continuation) = AsyncStream.makeStream(of: Data.self)
        let adding = Task { await viewModel.addPhotos([loader(waitingFor: stream)]) }
        while !viewModel.isProcessingPhotos {
            await Task.yield()
        }

        viewModel.removePhoto(at: 0)
        continuation.yield(Data("a".utf8))
        await adding.value

        XCTAssertEqual(viewModel.photos, [])
        XCTAssertNil(viewModel.photoErrorMessage)
    }

    func testAPhotoThatFailsIsDroppedAndReportedWhileTheOthersAreAdded() async {
        let viewModel = makeViewModel(
            mode: .create,
            photoProcessor: FakePhotoProcessor(fails: { $0 == Data("junk".utf8) })
        )

        await viewModel.addPhotos([
            loader("a"),
            { throw LoadFailure() },
            { nil },
            loader("junk"),
            loader("b"),
        ])

        XCTAssertEqual(viewModel.photos.map(\.state), [
            .processed(FakePhotoProcessor.processed(Data("a".utf8))),
            .processed(FakePhotoProcessor.processed(Data("b".utf8))),
        ])
        XCTAssertEqual(viewModel.photoErrorMessage, String(localized: "A photo couldn't be added."))
    }

    func testAddingPhotosAgainClearsThePreviousError() async {
        let viewModel = makeViewModel(mode: .create)
        await viewModel.addPhotos([{ nil }])
        XCTAssertNotNil(viewModel.photoErrorMessage)

        await viewModel.addPhotos([loader("a")])

        XCTAssertNil(viewModel.photoErrorMessage)
        XCTAssertEqual(viewModel.photos.count, 1)
    }

    func testAddingNoPhotosChangesNothing() async {
        let viewModel = makeViewModel(mode: .create)
        await viewModel.addPhotos([{ nil }])

        await viewModel.addPhotos([])

        XCTAssertNotNil(viewModel.photoErrorMessage)
    }

    // MARK: arranging

    func testMakeCoverMovesThePhotoToTheFront() {
        let ids = (0..<3).map { _ in UUID() }
        let viewModel = makeViewModel(mode: .edit(makeRecipe(photos: ids.map(RecipePhoto.init))))

        viewModel.makeCover(at: 2)

        XCTAssertEqual(viewModel.photos.map(\.id), [ids[2], ids[0], ids[1]])
    }

    func testMoveLeftAndRightSwapWithTheNeighbor() {
        let ids = (0..<3).map { _ in UUID() }
        let viewModel = makeViewModel(mode: .edit(makeRecipe(photos: ids.map(RecipePhoto.init))))

        viewModel.movePhotoLeft(at: 1)
        XCTAssertEqual(viewModel.photos.map(\.id), [ids[1], ids[0], ids[2]])

        viewModel.movePhotoRight(at: 1)
        XCTAssertEqual(viewModel.photos.map(\.id), [ids[1], ids[2], ids[0]])
    }

    func testArrangingOutOfRangeOrPastTheEndsChangesNothing() {
        let ids = (0..<2).map { _ in UUID() }
        let viewModel = makeViewModel(mode: .edit(makeRecipe(photos: ids.map(RecipePhoto.init))))

        viewModel.makeCover(at: 0)
        viewModel.makeCover(at: 5)
        viewModel.movePhotoLeft(at: 0)
        viewModel.movePhotoRight(at: 1)
        viewModel.removePhoto(at: 2)

        XCTAssertEqual(viewModel.photos.map(\.id), ids)
    }

    // MARK: thumbnails

    func testThumbnailComesFromTheStoreForASavedPhotoAndFromMemoryForANewOne() async {
        let stored = RecipePhoto(id: UUID())
        let missing = RecipePhoto(id: UUID())
        let viewModel = makeViewModel(
            mode: .edit(makeRecipe(photos: [stored, missing])),
            thumbnails: [stored.id: Data("stored thumb".utf8)]
        )
        await viewModel.addPhotos([loader("a")])

        XCTAssertEqual(viewModel.thumbnailData(for: viewModel.photos[0]), Data("stored thumb".utf8))
        XCTAssertNil(viewModel.thumbnailData(for: viewModel.photos[1]))
        XCTAssertEqual(viewModel.thumbnailData(for: viewModel.photos[2]), FakePhotoProcessor.processed(Data("a".utf8)).thumbnailData)
    }

    // MARK: helpers

    private func loader(_ text: String) -> RecipeFormViewModel.PhotoLoader {
        { Data(text.utf8) }
    }

    /// Loads the first data the stream yields, so a test can hold a photo in processing.
    private func loader(waitingFor stream: AsyncStream<Data>) -> RecipeFormViewModel.PhotoLoader {
        {
            for await data in stream {
                return data
            }
            return nil
        }
    }

    private func makeRecipe(photos: [RecipePhoto]) -> Recipe {
        Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [], photos: photos)
    }

    private func makeViewModel(
        mode: RecipeFormMode,
        thumbnails: [UUID: Data] = [:],
        photoProcessor: PhotoProcessor = FakePhotoProcessor()
    ) -> RecipeFormViewModel {
        RecipeFormViewModel(mode: mode, dependencies: .testing(
            createRecipeUseCase: createUseCase,
            updateRecipeUseCase: updateUseCase,
            fetchTagsUseCase: NoOpFetchTagsUseCase(),
            findOrCreateTagUseCase: NoOpFindOrCreateTagUseCase(),
            fetchPhotoThumbnailUseCase: StubFetchPhotoThumbnailUseCase(thumbnails: thumbnails),
            photoProcessor: photoProcessor
        ))
    }
}
