import XCTest
@testable import PocketChef

private struct FakeFetchRecipesUseCase: FetchRecipesUseCase {
    var result: Result<[Recipe], Error>

    func execute() throws -> [Recipe] {
        try result.get()
    }
}

private struct UseCaseFailure: LocalizedError {
    var errorDescription: String? { "Something went wrong" }
}

final class RecipeListViewModelTests: XCTestCase {
    func testLoadPopulatesRecipesOnSuccess() {
        let recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])
        let viewModel = RecipeListViewModel(fetchRecipesUseCase: FakeFetchRecipesUseCase(result: .success([recipe])))

        viewModel.load()

        XCTAssertEqual(viewModel.recipes, [recipe])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadSetsErrorMessageOnFailureAndClearsRecipes() {
        let viewModel = RecipeListViewModel(fetchRecipesUseCase: FakeFetchRecipesUseCase(result: .failure(UseCaseFailure())))

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
        let viewModel = RecipeListViewModel(fetchRecipesUseCase: useCase)

        viewModel.load()
        XCTAssertNotNil(viewModel.errorMessage)

        viewModel.load()

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.recipes, [recipe])
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
