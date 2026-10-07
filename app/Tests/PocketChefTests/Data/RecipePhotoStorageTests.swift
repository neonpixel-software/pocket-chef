@testable import PocketChef
import SwiftData
import XCTest

/// Photos saved through SwiftDataRecipeRepository, mapped back in gallery order, and loaded
/// through SwiftDataRecipePhotoRepository.
final class RecipePhotoStorageTests: XCTestCase {
    private func makeInMemoryContext() throws -> ModelContext {
        try ModelContext(ModelContainer.inMemory())
    }

    private func bytes(_ byte: UInt8) -> ProcessedPhoto {
        ProcessedPhoto(imageData: Data([byte, 1]), thumbnailData: Data([byte, 2]))
    }

    private func recipe(photos: [UUID]) -> Recipe {
        var recipe = Recipe(id: UUID(), title: "Banana Bread", ingredients: [], steps: [], source: .typed, tags: [])
        recipe.photos = photos.map(RecipePhoto.init)
        return recipe
    }

    private func photoRows(in context: ModelContext) throws -> [RecipePhotoModel] {
        try context.fetch(FetchDescriptor<RecipePhotoModel>())
    }

    private func storedRecipe(in context: ModelContext) throws -> Recipe {
        try XCTUnwrap(SwiftDataRecipeRepository(modelContext: context).fetchAll().first)
    }

    func testCreateStoresNewPhotosInGalleryOrderWithTheirBytes() throws {
        let context = try makeInMemoryContext()
        let repository = SwiftDataRecipeRepository(modelContext: context)
        let cover = UUID(), second = UUID()
        let recipe = recipe(photos: [cover, second])

        try repository.create(recipe, newPhotos: [cover: bytes(1), second: bytes(2)])

        XCTAssertEqual(try storedRecipe(in: context).photos, recipe.photos)
        let photos = SwiftDataRecipePhotoRepository(modelContext: context)
        XCTAssertEqual(try photos.image(id: cover), bytes(1).imageData)
        XCTAssertEqual(try photos.thumbnail(id: cover), bytes(1).thumbnailData)
        XCTAssertEqual(try photos.image(id: second), bytes(2).imageData)
        XCTAssertEqual(try photoRows(in: context).map(\.position).sorted(), [0, 1])
    }

    func testCreateSkipsAPhotoWithoutStoredRowOrBytes() throws {
        let context = try makeInMemoryContext()
        let kept = UUID()

        try SwiftDataRecipeRepository(modelContext: context)
            .create(recipe(photos: [UUID(), kept]), newPhotos: [kept: bytes(1)])

        XCTAssertEqual(try storedRecipe(in: context).photos, [RecipePhoto(id: kept)])
        XCTAssertEqual(try photoRows(in: context).first?.position, 0)
    }

    func testUpdateReordersAddsAndRemovesPhotosKeepingExistingRows() throws {
        let context = try makeInMemoryContext()
        let repository = SwiftDataRecipeRepository(modelContext: context)
        let first = UUID(), second = UUID(), removed = UUID(), added = UUID()
        var recipe = recipe(photos: [first, second, removed])
        try repository.create(recipe, newPhotos: [first: bytes(1), second: bytes(2), removed: bytes(3)])
        let rowBefore = try XCTUnwrap(photoRows(in: context).first { $0.id == second })

        recipe.photos = [second, added, first].map(RecipePhoto.init)
        try repository.update(recipe, newPhotos: [added: bytes(4)])

        XCTAssertEqual(try storedRecipe(in: context).photos, recipe.photos)
        let rows = try photoRows(in: context)
        XCTAssertEqual(rows.count, 3, "the removed photo's row is deleted")
        XCTAssertTrue(rows.contains { $0 === rowBefore }, "an existing photo keeps its row, so it isn't uploaded again")
        let positions = Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0.position) })
        XCTAssertEqual(positions, [second: 0, added: 1, first: 2])
        XCTAssertNil(try SwiftDataRecipePhotoRepository(modelContext: context).image(id: removed))
    }

    func testUpdateWithoutPhotoBytesKeepsTheGallery() throws {
        let context = try makeInMemoryContext()
        let repository = SwiftDataRecipeRepository(modelContext: context)
        let photo = UUID()
        var recipe = recipe(photos: [photo])
        try repository.create(recipe, newPhotos: [photo: bytes(1)])

        recipe.title = "Better Banana Bread"
        try repository.update(recipe)

        XCTAssertEqual(try storedRecipe(in: context).photos, [RecipePhoto(id: photo)])
        XCTAssertEqual(try SwiftDataRecipePhotoRepository(modelContext: context).image(id: photo), bytes(1).imageData)
    }

    /// Two devices reordering offline can leave colliding positions (CloudKit merges per record).
    func testCollidingPositionsSortByIDAndTheNextSaveNumbersThemAgain() throws {
        let context = try makeInMemoryContext()
        let low = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        let high = try XCTUnwrap(UUID(uuidString: "FFFFFFFF-0000-0000-0000-000000000001"))
        let last = UUID()
        context.insert(RecipeModel(title: "Banana Bread", steps: [], isTypedSource: true, photos: [
            RecipePhotoModel(id: last, position: 1, imageData: Data([3]), thumbnailData: Data([3])),
            RecipePhotoModel(id: high, position: 0, imageData: Data([2]), thumbnailData: Data([2])),
            RecipePhotoModel(id: low, position: 0, imageData: Data([1]), thumbnailData: Data([1])),
        ]))
        try context.save()

        let recipe = try storedRecipe(in: context)
        XCTAssertEqual(recipe.photos.map(\.id), [low, high, last])

        try SwiftDataRecipeRepository(modelContext: context).update(recipe)

        let positions = try Dictionary(uniqueKeysWithValues: photoRows(in: context).map { ($0.id, $0.position) })
        XCTAssertEqual(positions, [low: 0, high: 1, last: 2])
    }

    func testSavingDeletesADuplicateRowForTheSamePhoto() throws {
        let context = try makeInMemoryContext()
        let photo = UUID()
        context.insert(RecipeModel(title: "Banana Bread", steps: [], isTypedSource: true, photos: [
            RecipePhotoModel(id: photo, position: 0, imageData: Data([1]), thumbnailData: Data([1])),
            RecipePhotoModel(id: photo, position: 1, imageData: Data([1]), thumbnailData: Data([1])),
        ]))
        try context.save()

        let recipe = try storedRecipe(in: context)
        XCTAssertEqual(recipe.photos, [RecipePhoto(id: photo), RecipePhoto(id: photo)])
        try SwiftDataRecipeRepository(modelContext: context).update(recipe)

        XCTAssertEqual(try storedRecipe(in: context).photos, [RecipePhoto(id: photo)])
        XCTAssertEqual(try photoRows(in: context).count, 1)
    }

    func testDeletingARecipeDeletesItsPhotos() throws {
        let context = try makeInMemoryContext()
        let repository = SwiftDataRecipeRepository(modelContext: context)
        let photo = UUID()
        let recipe = recipe(photos: [photo])
        try repository.create(recipe, newPhotos: [photo: bytes(1)])

        try repository.delete(id: recipe.id)

        XCTAssertEqual(try photoRows(in: context).count, 0)
    }

    func testPhotoRepositoryReturnsNilForAnUnknownPhoto() throws {
        let context = try makeInMemoryContext()
        let photos = SwiftDataRecipePhotoRepository(modelContext: context)

        XCTAssertNil(try photos.thumbnail(id: UUID()))
        XCTAssertNil(try photos.image(id: UUID()))
    }

    func testPhotoRepositoryReturnsNilWhileBytesAreNotOnThisDevice() throws {
        let context = try makeInMemoryContext()
        let photo = UUID()
        context.insert(RecipeModel(title: "Banana Bread", steps: [], isTypedSource: true, photos: [
            RecipePhotoModel(id: photo, imageData: nil, thumbnailData: nil),
        ]))
        try context.save()

        let photos = SwiftDataRecipePhotoRepository(modelContext: context)
        XCTAssertNil(try photos.thumbnail(id: photo))
        XCTAssertNil(try photos.image(id: photo))
        XCTAssertEqual(try storedRecipe(in: context).photos, [RecipePhoto(id: photo)])
    }
}
