import Foundation
import Observation

@Observable
final class RecipeListViewModel {
    private(set) var recipes: [Recipe] = []
    private(set) var errorMessage: String?

    private let fetchRecipesUseCase: FetchRecipesUseCase
    private let createRecipeUseCase: CreateRecipeUseCase
    private let updateRecipeUseCase: UpdateRecipeUseCase
    private let deleteRecipeUseCase: DeleteRecipeUseCase

    init(
        fetchRecipesUseCase: FetchRecipesUseCase,
        createRecipeUseCase: CreateRecipeUseCase,
        updateRecipeUseCase: UpdateRecipeUseCase,
        deleteRecipeUseCase: DeleteRecipeUseCase
    ) {
        self.fetchRecipesUseCase = fetchRecipesUseCase
        self.createRecipeUseCase = createRecipeUseCase
        self.updateRecipeUseCase = updateRecipeUseCase
        self.deleteRecipeUseCase = deleteRecipeUseCase
    }

    func load() {
        do {
            recipes = try fetchRecipesUseCase.execute()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ recipe: Recipe) {
        do {
            try deleteRecipeUseCase.execute(id: recipe.id)
            recipes.removeAll { $0.id == recipe.id }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func makeNewRecipeFormViewModel() -> RecipeFormViewModel {
        RecipeFormViewModel(
            mode: .create,
            createRecipeUseCase: createRecipeUseCase,
            updateRecipeUseCase: updateRecipeUseCase
        )
    }

    func makeDetailViewModel(for recipe: Recipe) -> RecipeDetailViewModel {
        RecipeDetailViewModel(
            recipe: recipe,
            createRecipeUseCase: createRecipeUseCase,
            updateRecipeUseCase: updateRecipeUseCase,
            deleteRecipeUseCase: deleteRecipeUseCase
        )
    }
}
