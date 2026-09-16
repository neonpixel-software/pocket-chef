import Foundation
import Observation

@Observable
final class RecipeListViewModel {
    private(set) var recipes: [Recipe] = []
    private(set) var allTags: [Tag] = []
    var selectedTagID: UUID?
    private(set) var errorMessage: String?

    private let fetchRecipesUseCase: FetchRecipesUseCase
    private let createRecipeUseCase: CreateRecipeUseCase
    private let updateRecipeUseCase: UpdateRecipeUseCase
    private let deleteRecipeUseCase: DeleteRecipeUseCase
    private let fetchTagsUseCase: FetchTagsUseCase
    private let findOrCreateTagUseCase: FindOrCreateTagUseCase

    init(
        fetchRecipesUseCase: FetchRecipesUseCase,
        createRecipeUseCase: CreateRecipeUseCase,
        updateRecipeUseCase: UpdateRecipeUseCase,
        deleteRecipeUseCase: DeleteRecipeUseCase,
        fetchTagsUseCase: FetchTagsUseCase,
        findOrCreateTagUseCase: FindOrCreateTagUseCase
    ) {
        self.fetchRecipesUseCase = fetchRecipesUseCase
        self.createRecipeUseCase = createRecipeUseCase
        self.updateRecipeUseCase = updateRecipeUseCase
        self.deleteRecipeUseCase = deleteRecipeUseCase
        self.fetchTagsUseCase = fetchTagsUseCase
        self.findOrCreateTagUseCase = findOrCreateTagUseCase
    }

    var filteredRecipes: [Recipe] {
        guard let selectedTagID else { return recipes }
        return recipes.filter { recipe in recipe.tags.contains { $0.id == selectedTagID } }
    }

    func load() {
        do {
            recipes = try fetchRecipesUseCase.execute()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadTags() {
        do {
            allTags = try fetchTagsUseCase.execute().sortedPresetsFirst()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectTag(_ id: UUID?) {
        selectedTagID = id
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
            updateRecipeUseCase: updateRecipeUseCase,
            fetchTagsUseCase: fetchTagsUseCase,
            findOrCreateTagUseCase: findOrCreateTagUseCase
        )
    }

    func makeDetailViewModel(for recipe: Recipe) -> RecipeDetailViewModel {
        RecipeDetailViewModel(
            recipe: recipe,
            createRecipeUseCase: createRecipeUseCase,
            updateRecipeUseCase: updateRecipeUseCase,
            deleteRecipeUseCase: deleteRecipeUseCase,
            fetchTagsUseCase: fetchTagsUseCase,
            findOrCreateTagUseCase: findOrCreateTagUseCase
        )
    }
}
