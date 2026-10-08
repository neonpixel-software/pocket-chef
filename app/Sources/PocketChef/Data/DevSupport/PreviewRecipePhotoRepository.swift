#if DEBUG
import Foundation

/// SampleData recipes have no photos, so previews never load any bytes.
struct PreviewRecipePhotoRepository: RecipePhotoRepository {
    func thumbnail(id _: UUID) throws -> Data? { nil }
    func image(id _: UUID) throws -> Data? { nil }
}

extension RecipeFormViewModel.Dependencies {
    /// What the form and detail previews run against: SampleData, nothing persisted.
    static var preview: Self {
        Self(
            createRecipeUseCase: DefaultCreateRecipeUseCase(repository: PreviewRecipeRepository()),
            updateRecipeUseCase: DefaultUpdateRecipeUseCase(repository: PreviewRecipeRepository()),
            fetchTagsUseCase: DefaultFetchTagsUseCase(repository: PreviewTagRepository()),
            findOrCreateTagUseCase: DefaultFindOrCreateTagUseCase(repository: PreviewTagRepository()),
            fetchPhotoThumbnailUseCase: DefaultFetchPhotoThumbnailUseCase(repository: PreviewRecipePhotoRepository()),
            photoProcessor: ImageIOPhotoProcessor()
        )
    }
}
#endif
