import Foundation
import SwiftData

final class SwiftDataRecipePhotoRepository: RecipePhotoRepository {
    /// Resolved on every call, like SwiftDataRecipeRepository, so a storage switch retargets it.
    private let currentModelContext: () -> ModelContext

    init(modelContext: @escaping @autoclosure () -> ModelContext) {
        currentModelContext = modelContext
    }

    func thumbnail(id: UUID) throws -> Data? {
        try photo(id: id)?.thumbnailData
    }

    func image(id: UUID) throws -> Data? {
        try photo(id: id)?.imageData
    }

    private func photo(id: UUID) throws -> RecipePhotoModel? {
        var descriptor = FetchDescriptor<RecipePhotoModel>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try currentModelContext().fetch(descriptor).first
    }
}
