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
    private let captureRecipeUseCase: CaptureRecipeUseCase
    private let checkCaptureAvailabilityUseCase: CheckCaptureAvailabilityUseCase

    init(
        fetchRecipesUseCase: FetchRecipesUseCase,
        createRecipeUseCase: CreateRecipeUseCase,
        updateRecipeUseCase: UpdateRecipeUseCase,
        deleteRecipeUseCase: DeleteRecipeUseCase,
        fetchTagsUseCase: FetchTagsUseCase,
        findOrCreateTagUseCase: FindOrCreateTagUseCase,
        captureRecipeUseCase: CaptureRecipeUseCase,
        checkCaptureAvailabilityUseCase: CheckCaptureAvailabilityUseCase
    ) {
        self.fetchRecipesUseCase = fetchRecipesUseCase
        self.createRecipeUseCase = createRecipeUseCase
        self.updateRecipeUseCase = updateRecipeUseCase
        self.deleteRecipeUseCase = deleteRecipeUseCase
        self.fetchTagsUseCase = fetchTagsUseCase
        self.findOrCreateTagUseCase = findOrCreateTagUseCase
        self.captureRecipeUseCase = captureRecipeUseCase
        self.checkCaptureAvailabilityUseCase = checkCaptureAvailabilityUseCase
    }

    var filteredRecipes: [Recipe] {
        guard let selectedTagID else { return recipes }
        return recipes.filter { recipe in recipe.tags.contains { $0.id == selectedTagID } }
    }

    var isCaptureAvailable: Bool {
        checkCaptureAvailabilityUseCase.execute()
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

    func makeCaptureReviewFormViewModel(for recipe: Recipe) -> RecipeFormViewModel {
        RecipeFormViewModel(
            mode: .capture(recipe),
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

    @MainActor
    func makeCaptureViewModel() -> RecipeCaptureViewModel {
        RecipeCaptureViewModel(captureRecipeUseCase: captureRecipeUseCase)
    }
}
