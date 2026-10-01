import SwiftData
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
    /// The local-only density cache (Phase 10). Nil when the store couldn't open; the app
    /// works without it, since only unit conversion needs densities.
    private let densityContainer: ModelContainer?
    /// Nil without the store or the density API configuration (DensityAPI.xcconfig).
    private let refreshDensityCacheUseCase: RefreshDensityCacheUseCase?
    @Environment(\.scenePhase) private var scenePhase

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
        do {
            densityContainer = try DensityStore.makeContainer()
        } catch {
            print("Failed to open the density cache: \(error)")
            densityContainer = nil
        }
        if let densityContainer,
           let configuration = DensityAPIConfiguration(infoDictionary: Bundle.main.infoDictionary) {
            refreshDensityCacheUseCase = DefaultRefreshDensityCacheUseCase(
                remoteSource: URLSessionDensityEntryRemoteSource(configuration: configuration),
                cacheRepository: SwiftDataDensityCacheRepository(modelContext: densityContainer.mainContext),
                refreshLog: UserDefaultsDensityRefreshLog()
            )
        } else {
            refreshDensityCacheUseCase = nil
        }

        settingsViewModel = SettingsViewModel(
            changeStorageModeUseCase: DefaultChangeStorageModeUseCase(
                switcher: persistence,
                accountStatusProvider: CloudKitAccountStatusProvider(isEnabledInBuild: BuildConfiguration.isICloudEnabled)
            ),
            isICloudAvailableInBuild: BuildConfiguration.isICloudEnabled,
            refreshDensityCacheUseCase: refreshDensityCacheUseCase
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
            // The periodic check (Phase 10.2): on launch and whenever the app comes back,
            // refresh densities if the last refresh is more than a day old.
            .onChange(of: scenePhase, initial: true) { _, phase in
                guard phase == .active, let refreshDensityCacheUseCase else { return }
                Task {
                    do {
                        try await refreshDensityCacheUseCase.executeIfStale()
                    } catch {
                        print("Refreshing ingredient densities failed: \(error)")
                    }
                }
            }
        }

        #if os(macOS)
        Settings {
            SettingsView(viewModel: settingsViewModel)
        }
        #endif
    }
}
