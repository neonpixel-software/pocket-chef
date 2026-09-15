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
    private let fetchTagsUseCase: FetchTagsUseCase
    private let findOrCreateTagUseCase: FindOrCreateTagUseCase

    init(
        recipe: Recipe,
        createRecipeUseCase: CreateRecipeUseCase,
        updateRecipeUseCase: UpdateRecipeUseCase,
        deleteRecipeUseCase: DeleteRecipeUseCase,
        fetchTagsUseCase: FetchTagsUseCase,
        findOrCreateTagUseCase: FindOrCreateTagUseCase
    ) {
        self.recipe = recipe
        self.createRecipeUseCase = createRecipeUseCase
        self.updateRecipeUseCase = updateRecipeUseCase
        self.deleteRecipeUseCase = deleteRecipeUseCase
        self.fetchTagsUseCase = fetchTagsUseCase
        self.findOrCreateTagUseCase = findOrCreateTagUseCase
    }

    func makeEditFormViewModel() -> RecipeFormViewModel {
        RecipeFormViewModel(
            mode: .edit(recipe),
            createRecipeUseCase: createRecipeUseCase,
            updateRecipeUseCase: updateRecipeUseCase,
            fetchTagsUseCase: fetchTagsUseCase,
            findOrCreateTagUseCase: findOrCreateTagUseCase
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
