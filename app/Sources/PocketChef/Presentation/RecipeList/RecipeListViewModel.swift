import Foundation
import Observation

@Observable
final class RecipeListViewModel {
    /// Bundles the view model's use case dependencies into one parameter so the initializer
    /// stays under SonarCloud's constructor-arity limit. Relies on Swift's synthesized
    /// memberwise initializer rather than writing one by hand, since a hand-written
    /// initializer here would just move the same arity problem into this struct.
    struct Dependencies {
        let fetchRecipesUseCase: FetchRecipesUseCase
        let createRecipeUseCase: CreateRecipeUseCase
        let updateRecipeUseCase: UpdateRecipeUseCase
        let deleteRecipeUseCase: DeleteRecipeUseCase
        let fetchTagsUseCase: FetchTagsUseCase
        let findOrCreateTagUseCase: FindOrCreateTagUseCase
        let captureRecipeUseCase: CaptureRecipeUseCase
        let checkCaptureAvailabilityUseCase: CheckCaptureAvailabilityUseCase
        let captureRecipeFromURLUseCase: CaptureRecipeFromURLUseCase
        let fetchPhotoThumbnailUseCase: FetchPhotoThumbnailUseCase
        let photoProcessor: PhotoProcessor

        var form: RecipeFormViewModel.Dependencies {
            RecipeFormViewModel.Dependencies(
                createRecipeUseCase: createRecipeUseCase,
                updateRecipeUseCase: updateRecipeUseCase,
                fetchTagsUseCase: fetchTagsUseCase,
                findOrCreateTagUseCase: findOrCreateTagUseCase,
                fetchPhotoThumbnailUseCase: fetchPhotoThumbnailUseCase,
                photoProcessor: photoProcessor
            )
        }
    }

    private(set) var recipes: [Recipe] = []
    private(set) var allTags: [Tag] = []
    var selectedTagID: UUID?
    private(set) var errorMessage: String?

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    var filteredRecipes: [Recipe] {
        guard let selectedTagID else { return recipes }
        return recipes.filter { recipe in recipe.tags.contains { $0.id == selectedTagID } }
    }

    var isCaptureAvailable: Bool {
        dependencies.checkCaptureAvailabilityUseCase.execute()
    }

    func load() {
        do {
            recipes = try dependencies.fetchRecipesUseCase.execute()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadTags() {
        do {
            allTags = try dependencies.fetchTagsUseCase.execute().sortedPresetsFirst()
            // After a storage switch or a tag merge the selected tag can be gone, which would
            // leave the list filtered by a chip that no longer exists.
            if let selectedTagID, !allTags.contains(where: { $0.id == selectedTagID }) {
                self.selectedTagID = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectTag(_ id: UUID?) {
        selectedTagID = id
    }

    func delete(_ recipe: Recipe) {
        do {
            try dependencies.deleteRecipeUseCase.execute(id: recipe.id)
            recipes.removeAll { $0.id == recipe.id }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func makeNewRecipeFormViewModel() -> RecipeFormViewModel {
        RecipeFormViewModel(mode: .create, dependencies: dependencies.form)
    }

    @MainActor
    func makeCaptureReviewFormViewModel(for recipe: Recipe) -> RecipeFormViewModel {
        RecipeFormViewModel(mode: .capture(recipe), dependencies: dependencies.form)
    }

    func makeDetailViewModel(for recipe: Recipe) -> RecipeDetailViewModel {
        RecipeDetailViewModel(
            recipe: recipe,
            formDependencies: dependencies.form,
            deleteRecipeUseCase: dependencies.deleteRecipeUseCase
        )
    }

    @MainActor
    func makeCaptureViewModel() -> RecipeCaptureViewModel {
        RecipeCaptureViewModel(captureRecipeUseCase: dependencies.captureRecipeUseCase)
    }

    @MainActor
    func makeURLCaptureViewModel() -> RecipeURLCaptureViewModel {
        RecipeURLCaptureViewModel(captureRecipeFromURLUseCase: dependencies.captureRecipeFromURLUseCase)
    }
}
