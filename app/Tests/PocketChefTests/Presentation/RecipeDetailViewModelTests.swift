@testable import PocketChef
import XCTest

private struct NoOpCreateRecipeUseCase: CreateRecipeUseCase {
    func execute(_: Recipe, newPhotos _: [UUID: ProcessedPhoto]) throws {}
}

private struct NoOpUpdateRecipeUseCase: UpdateRecipeUseCase {
    func execute(_: Recipe, newPhotos _: [UUID: ProcessedPhoto]) throws {}
}

private struct FakeDeleteRecipeUseCase: DeleteRecipeUseCase {
    var result: Result<Void, Error> = .success(())
    let onExecute: ((UUID) -> Void)?

    init(result: Result<Void, Error> = .success(()), onExecute: ((UUID) -> Void)? = nil) {
        self.result = result
        self.onExecute = onExecute
    }

    func execute(id: UUID) throws {
        onExecute?(id)
        try result.get()
    }
}

private struct NoOpFetchTagsUseCase: FetchTagsUseCase {
    func execute() throws -> [Tag] { [] }
}

private struct NoOpFindOrCreateTagUseCase: FindOrCreateTagUseCase {
    func execute(name: String) throws -> Tag {
        Tag(id: UUID(), name: name, isPreset: false)
    }
}

private struct UseCaseFailure: LocalizedError {
    var errorDescription: String? { "Something went wrong" }
}

private func makeViewModel(
    recipe: Recipe,
    deleteRecipeUseCase: FakeDeleteRecipeUseCase = FakeDeleteRecipeUseCase(),
    images: [UUID: Data] = [:]
) -> RecipeDetailViewModel {
    RecipeDetailViewModel(
        recipe: recipe,
        formDependencies: .testing(
            createRecipeUseCase: NoOpCreateRecipeUseCase(),
            updateRecipeUseCase: NoOpUpdateRecipeUseCase(),
            fetchTagsUseCase: NoOpFetchTagsUseCase(),
            findOrCreateTagUseCase: NoOpFindOrCreateTagUseCase()
        ),
        deleteRecipeUseCase: deleteRecipeUseCase,
        fetchPhotoImageUseCase: StubFetchPhotoImageUseCase(images: images)
    )
}

@MainActor
final class RecipeDetailViewModelTests: XCTestCase {
    func testDeleteSetsIsDeletedOnSuccess() {
        let recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])
        var deletedID: UUID?
        let viewModel = makeViewModel(recipe: recipe, deleteRecipeUseCase: FakeDeleteRecipeUseCase(onExecute: { deletedID = $0 }))

        viewModel.delete()

        XCTAssertTrue(viewModel.isDeleted)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(deletedID, recipe.id)
    }

    func testImageDataIsThePhotosImageOrNilWhenItIsntHere() {
        let here = RecipePhoto(id: UUID())
        let missing = RecipePhoto(id: UUID())
        let recipe = Recipe(id: UUID(), title: "Salad", ingredients: [], steps: [], source: .typed, tags: [], photos: [here, missing])
        let viewModel = makeViewModel(recipe: recipe, images: [here.id: Data([3])])

        XCTAssertEqual(viewModel.imageData(for: here), Data([3]))
        XCTAssertNil(viewModel.imageData(for: missing))
    }

    func testDeleteSetsErrorMessageAndLeavesIsDeletedFalseOnFailure() {
        let recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])
        let viewModel = makeViewModel(recipe: recipe, deleteRecipeUseCase: FakeDeleteRecipeUseCase(result: .failure(UseCaseFailure())))

        viewModel.delete()

        XCTAssertFalse(viewModel.isDeleted)
        XCTAssertEqual(viewModel.errorMessage, "Something went wrong")
    }

    func testMakeEditFormViewModelPrefillsFromCurrentRecipe() {
        let recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])
        let viewModel = makeViewModel(recipe: recipe)

        let formViewModel = viewModel.makeEditFormViewModel()

        XCTAssertEqual(formViewModel.title, "Pancakes")
    }
}
