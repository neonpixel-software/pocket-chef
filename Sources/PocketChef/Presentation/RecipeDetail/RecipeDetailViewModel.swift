import Foundation
import Observation

@Observable
final class RecipeDetailViewModel {
    var recipe: Recipe
    var isPresentingEdit = false
    var isPresentingDeleteConfirmation = false
    private(set) var errorMessage: String?
    private(set) var isDeleted = false

    private let createRecipeUseCase: CreateRecipeUseCase
    private let updateRecipeUseCase: UpdateRecipeUseCase
    private let deleteRecipeUseCase: DeleteRecipeUseCase

    init(
        recipe: Recipe,
        createRecipeUseCase: CreateRecipeUseCase,
        updateRecipeUseCase: UpdateRecipeUseCase,
        deleteRecipeUseCase: DeleteRecipeUseCase
    ) {
        self.recipe = recipe
        self.createRecipeUseCase = createRecipeUseCase
        self.updateRecipeUseCase = updateRecipeUseCase
        self.deleteRecipeUseCase = deleteRecipeUseCase
    }

    func makeEditFormViewModel() -> RecipeFormViewModel {
        RecipeFormViewModel(
            mode: .edit(recipe),
            createRecipeUseCase: createRecipeUseCase,
            updateRecipeUseCase: updateRecipeUseCase
        )
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
