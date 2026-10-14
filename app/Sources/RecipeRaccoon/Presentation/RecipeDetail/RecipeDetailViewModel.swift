import Foundation
import Observation

@Observable
final class RecipeDetailViewModel {
    var recipe: Recipe
    var isPresentingEdit = false
    var isPresentingDeleteConfirmation = false
    private(set) var errorMessage: String?
    private(set) var isDeleted = false

    private let formDependencies: RecipeFormViewModel.Dependencies
    private let deleteRecipeUseCase: DeleteRecipeUseCase
    private let fetchPhotoImageUseCase: FetchPhotoImageUseCase

    init(
        recipe: Recipe,
        formDependencies: RecipeFormViewModel.Dependencies,
        deleteRecipeUseCase: DeleteRecipeUseCase,
        fetchPhotoImageUseCase: FetchPhotoImageUseCase
    ) {
        self.recipe = recipe
        self.formDependencies = formDependencies
        self.deleteRecipeUseCase = deleteRecipeUseCase
        self.fetchPhotoImageUseCase = fetchPhotoImageUseCase
    }

    /// A gallery photo's full image, or nil while its bytes aren't on this device.
    func imageData(for photo: RecipePhoto) -> Data? {
        try? fetchPhotoImageUseCase.execute(id: photo.id)
    }

    @MainActor
    func makeEditFormViewModel() -> RecipeFormViewModel {
        RecipeFormViewModel(mode: .edit(recipe), dependencies: formDependencies)
    }

    func delete() {
        do {
            try deleteRecipeUseCase.execute(id: recipe.id)
            errorMessage = nil
            isDeleted = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
