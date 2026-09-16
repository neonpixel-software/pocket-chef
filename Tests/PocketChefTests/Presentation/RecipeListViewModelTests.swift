import XCTest
@testable import PocketChef

private struct FakeFetchRecipesUseCase: FetchRecipesUseCase {
    var result: Result<[Recipe], Error>

    func execute() throws -> [Recipe] {
        try result.get()
    }
}

private struct NoOpCreateRecipeUseCase: CreateRecipeUseCase {
    func execute(_ recipe: Recipe) throws {}
}

private struct NoOpUpdateRecipeUseCase: UpdateRecipeUseCase {
    func execute(_ recipe: Recipe) throws {}
}

private struct FakeDeleteRecipeUseCase: DeleteRecipeUseCase {
    var result: Result<Void, Error> = .success(())

    func execute(id: UUID) throws {
        try result.get()
    }
}

private struct FakeFetchTagsUseCase: FetchTagsUseCase {
    var result: Result<[Tag], Error> = .success([])

    func execute() throws -> [Tag] {
        try result.get()
    }
}

private struct NoOpFindOrCreateTagUseCase: FindOrCreateTagUseCase {
    func execute(name: String) throws -> Tag {
        Tag(id: UUID(), name: name, isPreset: false)
    }
}

private struct NoOpCaptureRecipeUseCase: CaptureRecipeUseCase {
    func execute(text: String) async throws -> Recipe {
        Recipe(id: UUID(), title: "", ingredients: [], steps: [], source: .typed, tags: [])
    }
}

private struct FakeCheckCaptureAvailabilityUseCase: CheckCaptureAvailabilityUseCase {
    var result = true
    func execute() -> Bool { result }
}

private struct NoOpCaptureRecipeFromURLUseCase: CaptureRecipeFromURLUseCase {
    func execute(urlString: String) async throws -> Recipe {
        Recipe(id: UUID(), title: "", ingredients: [], steps: [], source: .typed, tags: [])
    }
}

private struct UseCaseFailure: LocalizedError {
    var errorDescription: String? { "Something went wrong" }
}

private func makeViewModel(
    fetchResult: Result<[Recipe], Error> = .success([]),
    deleteResult: Result<Void, Error> = .success(()),
    fetchTagsResult: Result<[Tag], Error> = .success([]),
    captureAvailable: Bool = true
) -> RecipeListViewModel {
    RecipeListViewModel(
        fetchRecipesUseCase: FakeFetchRecipesUseCase(result: fetchResult),
        createRecipeUseCase: NoOpCreateRecipeUseCase(),
        updateRecipeUseCase: NoOpUpdateRecipeUseCase(),
        deleteRecipeUseCase: FakeDeleteRecipeUseCase(result: deleteResult),
        fetchTagsUseCase: FakeFetchTagsUseCase(result: fetchTagsResult),
        findOrCreateTagUseCase: NoOpFindOrCreateTagUseCase(),
        captureRecipeUseCase: NoOpCaptureRecipeUseCase(),
        checkCaptureAvailabilityUseCase: FakeCheckCaptureAvailabilityUseCase(result: captureAvailable),
        captureRecipeFromURLUseCase: NoOpCaptureRecipeFromURLUseCase()
    )
}

final class RecipeListViewModelTests: XCTestCase {
    func testLoadPopulatesRecipesOnSuccess() {
        let recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])
        let viewModel = makeViewModel(fetchResult: .success([recipe]))

        viewModel.load()

        XCTAssertEqual(viewModel.recipes, [recipe])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadSetsErrorMessageOnFailureAndClearsRecipes() {
        let viewModel = makeViewModel(fetchResult: .failure(UseCaseFailure()))

        viewModel.load()

        XCTAssertEqual(viewModel.recipes, [])
        XCTAssertEqual(viewModel.errorMessage, "Something went wrong")
    }

    func testLoadClearsPreviousErrorOnSubsequentSuccess() {
        let recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])
        var call = 0
        let useCase = AnyThrowingFetchRecipesUseCase {
            call += 1
            if call == 1 { throw UseCaseFailure() }
            return [recipe]
        }
        let viewModel = RecipeListViewModel(
            fetchRecipesUseCase: useCase,
            createRecipeUseCase: NoOpCreateRecipeUseCase(),
            updateRecipeUseCase: NoOpUpdateRecipeUseCase(),
            deleteRecipeUseCase: FakeDeleteRecipeUseCase(),
            fetchTagsUseCase: FakeFetchTagsUseCase(),
            findOrCreateTagUseCase: NoOpFindOrCreateTagUseCase(),
            captureRecipeUseCase: NoOpCaptureRecipeUseCase(),
            checkCaptureAvailabilityUseCase: FakeCheckCaptureAvailabilityUseCase(),
            captureRecipeFromURLUseCase: NoOpCaptureRecipeFromURLUseCase()
        )

        viewModel.load()
        XCTAssertNotNil(viewModel.errorMessage)

        viewModel.load()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.recipes, [recipe])
    }

    func testDeleteRemovesRecipeFromListOnSuccess() {
        let recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])
        let viewModel = makeViewModel(fetchResult: .success([recipe]))
        viewModel.load()

        viewModel.delete(recipe)

        XCTAssertEqual(viewModel.recipes, [])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testDeleteSetsErrorMessageOnFailureAndKeepsRecipe() {
        let recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])
        let viewModel = makeViewModel(fetchResult: .success([recipe]), deleteResult: .failure(UseCaseFailure()))
        viewModel.load()

        viewModel.delete(recipe)

        XCTAssertEqual(viewModel.recipes, [recipe])
        XCTAssertEqual(viewModel.errorMessage, "Something went wrong")
    }

    func testMakeNewRecipeFormViewModelStartsBlank() {
        let viewModel = makeViewModel()

        let formViewModel = viewModel.makeNewRecipeFormViewModel()

        XCTAssertEqual(formViewModel.title, "")
        XCTAssertFalse(formViewModel.canSave)
    }

    func testMakeDetailViewModelCarriesTheGivenRecipe() {
        let recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])
        let viewModel = makeViewModel()

        let detailViewModel = viewModel.makeDetailViewModel(for: recipe)

        XCTAssertEqual(detailViewModel.recipe, recipe)
    }

    // MARK: tag filtering

    func testLoadTagsPopulatesAllTagsSortedPresetsFirst() {
        let breakfast = Tag(id: UUID(), name: "Breakfast", isPreset: true)
        let spicy = Tag(id: UUID(), name: "Spicy", isPreset: false)
        let viewModel = makeViewModel(fetchTagsResult: .success([spicy, breakfast]))

        viewModel.loadTags()

        XCTAssertEqual(viewModel.allTags, [breakfast, spicy])
    }

    func testFilteredRecipesReturnsAllRecipesWhenNoTagSelected() {
        let breakfast = Tag(id: UUID(), name: "Breakfast", isPreset: true)
        let pancakes = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [breakfast])
        let soup = Recipe(id: UUID(), title: "Soup", ingredients: [], steps: [], source: .typed, tags: [])
        let viewModel = makeViewModel(fetchResult: .success([pancakes, soup]))
        viewModel.load()

        XCTAssertEqual(viewModel.filteredRecipes, [pancakes, soup])
    }

    func testSelectingATagNarrowsFilteredRecipesAndClearingRestoresFullList() {
        let breakfast = Tag(id: UUID(), name: "Breakfast", isPreset: true)
        let pancakes = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [breakfast])
        let soup = Recipe(id: UUID(), title: "Soup", ingredients: [], steps: [], source: .typed, tags: [])
        let viewModel = makeViewModel(fetchResult: .success([pancakes, soup]))
        viewModel.load()

        viewModel.selectTag(breakfast.id)
        XCTAssertEqual(viewModel.filteredRecipes, [pancakes])

        viewModel.selectTag(nil)
        XCTAssertEqual(viewModel.filteredRecipes, [pancakes, soup])
    }

    // MARK: capture

    func testIsCaptureAvailableReflectsUseCase() {
        XCTAssertTrue(makeViewModel(captureAvailable: true).isCaptureAvailable)
        XCTAssertFalse(makeViewModel(captureAvailable: false).isCaptureAvailable)
    }

    @MainActor
    func testMakeCaptureViewModelStartsBlank() {
        let viewModel = makeViewModel()

        let captureViewModel = viewModel.makeCaptureViewModel()

        XCTAssertEqual(captureViewModel.rawText, "")
        XCTAssertFalse(captureViewModel.canCapture)
    }

    func testMakeCaptureReviewFormViewModelPrefillsFromCapturedRecipe() {
        let recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])
        let viewModel = makeViewModel()

        let formViewModel = viewModel.makeCaptureReviewFormViewModel(for: recipe)

        XCTAssertEqual(formViewModel.title, "Pancakes")
    }

    @MainActor
    func testMakeURLCaptureViewModelStartsBlank() {
        let viewModel = makeViewModel()

        let urlCaptureViewModel = viewModel.makeURLCaptureViewModel()

        XCTAssertEqual(urlCaptureViewModel.urlText, "")
        XCTAssertFalse(urlCaptureViewModel.canCapture)
    }
}

private final class AnyThrowingFetchRecipesUseCase: FetchRecipesUseCase {
    private let block: () throws -> [Recipe]

    init(_ block: @escaping () throws -> [Recipe]) {
        self.block = block
    }

    func execute() throws -> [Recipe] {
        try block()
    }
}
