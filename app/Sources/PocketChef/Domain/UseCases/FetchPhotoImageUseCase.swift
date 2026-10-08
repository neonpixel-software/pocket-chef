import Foundation

protocol FetchPhotoImageUseCase {
    /// The full image, or nil when its bytes aren't on this device yet.
    func execute(id: UUID) throws -> Data?
}

final class DefaultFetchPhotoImageUseCase: FetchPhotoImageUseCase {
    private let repository: RecipePhotoRepository

    init(repository: RecipePhotoRepository) {
        self.repository = repository
    }

    func execute(id: UUID) throws -> Data? {
        try repository.image(id: id)
    }
}
