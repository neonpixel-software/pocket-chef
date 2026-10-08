@testable import PocketChef
import Foundation

/// Thumbnails by photo id; an unknown id has none, like a photo not downloaded yet.
struct StubFetchPhotoThumbnailUseCase: FetchPhotoThumbnailUseCase {
    var thumbnails: [UUID: Data] = [:]

    func execute(id: UUID) throws -> Data? {
        thumbnails[id]
    }
}

/// Turns any data into a ProcessedPhoto derived from it, unless `fails` returns true for it.
struct FakePhotoProcessor: PhotoProcessor {
    var fails: @Sendable (Data) -> Bool = { _ in false }

    func process(_ data: Data) async throws -> ProcessedPhoto {
        if fails(data) { throw PhotoProcessingError.unreadableImage }
        return Self.processed(data)
    }

    static func processed(_ data: Data) -> ProcessedPhoto {
        ProcessedPhoto(imageData: Data("image:".utf8) + data, thumbnailData: Data("thumb:".utf8) + data)
    }
}

extension RecipeFormViewModel.Dependencies {
    /// The form's dependencies with stand-ins for the ones a test doesn't care about.
    static func testing(
        createRecipeUseCase: CreateRecipeUseCase,
        updateRecipeUseCase: UpdateRecipeUseCase,
        fetchTagsUseCase: FetchTagsUseCase,
        findOrCreateTagUseCase: FindOrCreateTagUseCase,
        fetchPhotoThumbnailUseCase: FetchPhotoThumbnailUseCase = StubFetchPhotoThumbnailUseCase(),
        photoProcessor: PhotoProcessor = FakePhotoProcessor()
    ) -> Self {
        Self(
            createRecipeUseCase: createRecipeUseCase,
            updateRecipeUseCase: updateRecipeUseCase,
            fetchTagsUseCase: fetchTagsUseCase,
            findOrCreateTagUseCase: findOrCreateTagUseCase,
            fetchPhotoThumbnailUseCase: fetchPhotoThumbnailUseCase,
            photoProcessor: photoProcessor
        )
    }
}
