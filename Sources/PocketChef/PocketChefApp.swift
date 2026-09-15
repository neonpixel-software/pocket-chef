import SwiftUI
import SwiftData

@main
struct PocketChefApp: App {
    private let modelContainer: ModelContainer
    private let recipeRepository: RecipeRepository

    init() {
        PCFontRegistrar.registerCustomFonts()

        do {
            modelContainer = try ModelContainer(for: RecipeModel.self, IngredientLineModel.self, TagModel.self, DensityEntryModel.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        recipeRepository = SwiftDataRecipeRepository(modelContext: modelContainer.mainContext)

        #if DEBUG
        modelContainer.mainContext.seedSampleDataIfNeeded()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RecipeListView(viewModel: RecipeListViewModel(
                fetchRecipesUseCase: DefaultFetchRecipesUseCase(repository: recipeRepository),
                createRecipeUseCase: DefaultCreateRecipeUseCase(repository: recipeRepository),
                updateRecipeUseCase: DefaultUpdateRecipeUseCase(repository: recipeRepository),
                deleteRecipeUseCase: DefaultDeleteRecipeUseCase(repository: recipeRepository)
            ))
        }
        .modelContainer(modelContainer)
    }
}
