import SwiftData
import SwiftUI

@main
struct PocketChefApp: App {
    private let persistence: PersistenceController
    private let recipeRepository: RecipeRepository
    private let tagRepository: TagRepository
    private let photoRepository: RecipePhotoRepository
    private let captureService: RecipeCaptureService
    private let webPageFetcher: WebPageFetcher
    private let captureRecipeUseCase: CaptureRecipeUseCase
    private let settingsViewModel: SettingsViewModel
    /// The local-only density cache (Phase 10). Nil when the store couldn't open; the app
    /// works without it, since only unit conversion needs densities.
    private let densityContainer: ModelContainer?
    /// Nil without the store or the density API configuration (DensityAPI.xcconfig).
    private let refreshDensityCacheUseCase: RefreshDensityCacheUseCase?
    /// Nil only when the density store couldn't open.
    private let convertIngredientsToWeightUseCase: ConvertIngredientsToWeightUseCase?
    @Environment(\.scenePhase) private var scenePhase

    init() {
        PCFontRegistrar.registerCustomFonts()

        do {
            persistence = try PersistenceController(
                isICloudEnabledInBuild: BuildConfiguration.isICloudEnabled,
                seedsSampleData: Self.seedsSampleData,
                makeContainer: Self.makeContainer
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        let contextProvider = persistence.contextProvider
        recipeRepository = Self.recipeRepository(wrapping: SwiftDataRecipeRepository(modelContext: contextProvider.context))
        tagRepository = SwiftDataTagRepository(modelContext: contextProvider.context)
        photoRepository = SwiftDataRecipePhotoRepository(modelContext: contextProvider.context)
        captureService = FoundationModelsRecipeCaptureService()
        webPageFetcher = URLSessionWebPageFetcher()
        captureRecipeUseCase = DefaultCaptureRecipeUseCase(captureService: captureService)
        do {
            densityContainer = try DensityStore.makeContainer()
        } catch {
            print("Failed to open the density cache: \(error)")
            densityContainer = nil
        }
        convertIngredientsToWeightUseCase = densityContainer.map {
            DefaultConvertIngredientsToWeightUseCase(cacheRepository: SwiftDataDensityCacheRepository(modelContext: $0.mainContext))
        }
        if Self.usesDensityAPI, let densityContainer,
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

    // MARK: - UI test runs

    // A UI test run (-UITestScenario, Debug only) gets an in-memory store in a fixed state,
    // no sample recipes, no density API and a fixed-size Mac window; see
    // Data/DevSupport/UITestScenario.swift.
    #if DEBUG
    private static let uiTestScenario = UITestScenario.current()
    private static let seedsSampleData = uiTestScenario == nil
    private static let usesDensityAPI = uiTestScenario == nil
    #if os(macOS)
    private static let uiTestWindowSize = uiTestScenario.map { _ in UITestScenario.macContentSize }
    #else
    /// iOS windows always fill the screen.
    private static let uiTestWindowSize: CGSize? = nil
    #endif
    private static let makeContainer: PersistenceController.ContainerFactory =
        uiTestScenario?.makeContainer(for:) ?? RecipeStore.makeContainer(for:)

    private static func recipeRepository(wrapping repository: RecipeRepository) -> RecipeRepository {
        uiTestScenario?.recipeRepository(wrapping: repository) ?? repository
    }
    #else
    private static let seedsSampleData = false
    private static let usesDensityAPI = true
    private static let makeContainer: PersistenceController.ContainerFactory = RecipeStore.makeContainer(for:)

    private static func recipeRepository(wrapping repository: RecipeRepository) -> RecipeRepository {
        repository
    }
    #endif

    private func makeRecipeListViewModel() -> RecipeListViewModel {
        let viewModel = RecipeListViewModel(dependencies: .init(
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
            ),
            fetchPhotoThumbnailUseCase: DefaultFetchPhotoThumbnailUseCase(repository: photoRepository),
            photoProcessor: ImageIOPhotoProcessor()
        ))
        #if DEBUG
        // Tapping a chip doesn't reach the app on GitHub's macOS runner, so the scenario
        // starts with the tag selected instead.
        if let tagName = Self.uiTestScenario?.selectedTagName {
            viewModel.selectTag((try? tagRepository.fetchAll())?.first { $0.name == tagName }?.id)
        }
        #endif
        return viewModel
    }

    @ViewBuilder
    private var rootView: some View {
        #if DEBUG
        if Self.uiTestScenario?.opensRecipeDetail == true, let recipe = try? recipeRepository.fetchAll().first {
            NavigationStack {
                RecipeDetailView(viewModel: makeRecipeListViewModel().makeDetailViewModel(for: recipe))
            }
        } else {
            recipeList
        }
        #else
        recipeList
        #endif
    }

    private var recipeList: some View {
        RecipeListView(
            viewModel: makeRecipeListViewModel(),
            settingsViewModel: settingsViewModel
        )
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .environment(\.convertIngredientsToWeight, convertIngredientsToWeightUseCase)
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
                // Only UI test runs fix the window size; Release builds leave both modifiers out.
                #if DEBUG
                .frame(width: Self.uiTestWindowSize?.width, height: Self.uiTestWindowSize?.height)
                #endif
        }
        #if DEBUG && os(macOS)
        .windowResizability(Self.uiTestWindowSize == nil ? .automatic : .contentSize)
        #endif

        #if os(macOS)
        Settings {
            SettingsView(viewModel: settingsViewModel)
        }
        #endif
    }
}
