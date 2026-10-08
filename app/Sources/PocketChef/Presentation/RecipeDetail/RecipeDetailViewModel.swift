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

    init(
        recipe: Recipe,
        formDependencies: RecipeFormViewModel.Dependencies,
        deleteRecipeUseCase: DeleteRecipeUseCase
    ) {
        self.recipe = recipe
        self.formDependencies = formDependencies
        self.deleteRecipeUseCase = deleteRecipeUseCase
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
