import SwiftUI

@main
struct PocketChefApp: App {
    private let persistence: PersistenceController
    private let recipeRepository: RecipeRepository
    private let tagRepository: TagRepository
    private let captureService: RecipeCaptureService
    private let webPageFetcher: WebPageFetcher
    private let captureRecipeUseCase: CaptureRecipeUseCase
    private let settingsViewModel: SettingsViewModel

    init() {
        PCFontRegistrar.registerCustomFonts()

        #if DEBUG
        let seedsSampleData = true
        #else
        let seedsSampleData = false
        #endif

        do {
            persistence = try PersistenceController(
                isICloudEnabledInBuild: BuildConfiguration.isICloudEnabled,
                seedsSampleData: seedsSampleData,
                makeContainer: RecipeStore.makeContainer(for:)
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        let contextProvider = persistence.contextProvider
        recipeRepository = SwiftDataRecipeRepository(modelContext: contextProvider.context)
        tagRepository = SwiftDataTagRepository(modelContext: contextProvider.context)
        captureService = FoundationModelsRecipeCaptureService()
        webPageFetcher = URLSessionWebPageFetcher()
        captureRecipeUseCase = DefaultCaptureRecipeUseCase(captureService: captureService)
        settingsViewModel = SettingsViewModel(
            changeStorageModeUseCase: DefaultChangeStorageModeUseCase(
                switcher: persistence,
                accountStatusProvider: CloudKitAccountStatusProvider(isEnabledInBuild: BuildConfiguration.isICloudEnabled)
            ),
            isICloudAvailableInBuild: BuildConfiguration.isICloudEnabled
        )
    }

    var body: some Scene {
        WindowGroup {
            RecipeListView(
                viewModel: RecipeListViewModel(dependencies: .init(
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
                )),
                settingsViewModel: settingsViewModel
            )
        }

        #if os(macOS)
        Settings {
            SettingsView(viewModel: settingsViewModel)
        }
        #endif
    }
}
