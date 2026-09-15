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

private struct UseCaseFailure: LocalizedError {
    var errorDescription: String? { "Something went wrong" }
}

private func makeViewModel(
    fetchResult: Result<[Recipe], Error> = .success([]),
    deleteResult: Result<Void, Error> = .success(())
) -> RecipeListViewModel {
    RecipeListViewModel(
        fetchRecipesUseCase: FakeFetchRecipesUseCase(result: fetchResult),
        createRecipeUseCase: NoOpCreateRecipeUseCase(),
        updateRecipeUseCase: NoOpUpdateRecipeUseCase(),
        deleteRecipeUseCase: FakeDeleteRecipeUseCase(result: deleteResult)
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
            deleteRecipeUseCase: FakeDeleteRecipeUseCase()
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
