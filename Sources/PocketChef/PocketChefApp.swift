import SwiftUI
import SwiftData

@main
struct PocketChefApp: App {
    private let modelContainer: ModelContainer

    init() {
        PCFontRegistrar.registerCustomFonts()

        do {
            modelContainer = try ModelContainer(for: RecipeModel.self, IngredientLineModel.self, TagModel.self, DensityEntryModel.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        #if DEBUG
        modelContainer.mainContext.seedSampleDataIfNeeded()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            let repository = SwiftDataRecipeRepository(modelContext: modelContainer.mainContext)
            RecipeListView(viewModel: RecipeListViewModel(
                fetchRecipesUseCase: DefaultFetchRecipesUseCase(repository: repository),
                createRecipeUseCase: DefaultCreateRecipeUseCase(repository: repository),
                updateRecipeUseCase: DefaultUpdateRecipeUseCase(repository: repository),
                deleteRecipeUseCase: DefaultDeleteRecipeUseCase(repository: repository)
            ))
        }
        .modelContainer(modelContainer)
    }
}
