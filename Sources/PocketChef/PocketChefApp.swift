import SwiftUI
import SwiftData

@main
struct PocketChefApp: App {
    private let modelContainer: ModelContainer
    private let recipeRepository: RecipeRepository
    private let tagRepository: TagRepository
    private let captureService: RecipeCaptureService
    private let webPageFetcher: WebPageFetcher
    private let captureRecipeUseCase: CaptureRecipeUseCase

    init() {
        PCFontRegistrar.registerCustomFonts()

        do {
            modelContainer = try ModelContainer(for: RecipeModel.self, IngredientLineModel.self, TagModel.self, DensityEntryModel.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        recipeRepository = SwiftDataRecipeRepository(modelContext: modelContainer.mainContext)
        tagRepository = SwiftDataTagRepository(modelContext: modelContainer.mainContext)
        captureService = FoundationModelsRecipeCaptureService()
        webPageFetcher = URLSessionWebPageFetcher()
        captureRecipeUseCase = DefaultCaptureRecipeUseCase(captureService: captureService)

        modelContainer.mainContext.seedPresetTagsIfNeeded()

        #if DEBUG
        modelContainer.mainContext.seedSampleDataIfNeeded()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RecipeListView(viewModel: RecipeListViewModel(dependencies: .init(
                fetchRecipesUseCase: DefaultFetchRecipesUseCase(repository: recipeRepository),
                createRecipeUseCase: DefaultCreateRecipeUseCase(repository: recipeRepository),
                updateRecipeUseCase: DefaultUpdateRecipeUseCase(repository: recipeRepository),
                deleteRecipeUseCase: DefaultDeleteRecipeUseCase(repository: recipeRepository),
                fetchTagsUseCase: DefaultFetchTagsUseCase(repository: tagRepository),
                findOrCreateTagUseCase: DefaultFindOrCreateTagUseCase(repository: tagRepository),
                captureRecipeUseCase: captureRecipeUseCase,
                checkCaptureAvailabilityUseCase: DefaultCheckCaptureAvailabilityUseCase(captureService: captureService),
                captureRecipeFromURLUseCase: DefaultCaptureRecipeFromURLUseCase(
                    webPageFetcher: webPageFetcher,
                    captureRecipeUseCase: captureRecipeUseCase
                )
            )))
        }
        .modelContainer(modelContainer)
    }
}
