import Foundation

protocol FetchPhotoThumbnailUseCase {
    /// The thumbnail, or nil when its bytes aren't on this device yet.
    func execute(id: UUID) throws -> Data?
}

final class DefaultFetchPhotoThumbnailUseCase: FetchPhotoThumbnailUseCase {
    private let repository: RecipePhotoRepository

    init(repository: RecipePhotoRepository) {
        self.repository = repository
    }

    func execute(id: UUID) throws -> Data? {
        try repository.thumbnail(id: id)
    }
}
