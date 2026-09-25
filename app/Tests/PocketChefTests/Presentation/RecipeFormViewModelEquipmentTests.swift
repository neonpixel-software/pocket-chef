@testable import PocketChef
import XCTest

private struct NoOpCreateRecipeUseCase: CreateRecipeUseCase {
    func execute(_: Recipe) throws {}
}

private struct NoOpUpdateRecipeUseCase: UpdateRecipeUseCase {
    func execute(_: Recipe) throws {}
}

private struct NoOpFetchTagsUseCase: FetchTagsUseCase {
    func execute() throws -> [Tag] { [] }
}

private struct NoOpFindOrCreateTagUseCase: FindOrCreateTagUseCase {
    func execute(name: String) throws -> Tag {
        Tag(id: UUID(), name: name, isPreset: false)
    }
}

/// The Equipment section of the form (issue #82).
final class RecipeFormViewModelEquipmentTests: XCTestCase {
    func testAddRemoveMoveEquipment() {
        let viewModel = makeViewModel(mode: .create)

        viewModel.addEquipment()
        viewModel.equipment[0].name = "loaf pan"
        viewModel.addEquipment()
        viewModel.equipment[1].name = "whisk"

        viewModel.moveEquipmentDown(at: 0)
        XCTAssertEqual(viewModel.equipment.map(\.name), ["whisk", "loaf pan"])

        viewModel.moveEquipmentUp(at: 1)
        XCTAssertEqual(viewModel.equipment.map(\.name), ["loaf pan", "whisk"])

        viewModel.moveEquipmentUp(at: 0)
        viewModel.moveEquipmentDown(at: 1)
        XCTAssertEqual(viewModel.equipment.map(\.name), ["loaf pan", "whisk"])

        viewModel.removeEquipment(at: 0)
        XCTAssertEqual(viewModel.equipment.map(\.name), ["whisk"])
    }

    func testSaveTrimsEquipmentAndDropsBlankRows() throws {
        let viewModel = makeViewModel(mode: .create)
        viewModel.title = "Banana Bread"
        viewModel.addEquipment()
        viewModel.equipment[0].name = "  loaf pan  "
        viewModel.addEquipment() // blank, should be dropped

        let recipe = try XCTUnwrap(viewModel.save())

        XCTAssertEqual(recipe.equipment, ["loaf pan"])
    }

    func testSaveInEditModeKeepsUntouchedEquipment() throws {
        let original = Recipe(id: UUID(), title: "Bread", ingredients: [], equipment: ["loaf pan"], steps: [], source: .typed, tags: [])
        let viewModel = makeViewModel(mode: .edit(original))

        let recipe = try XCTUnwrap(viewModel.save())

        XCTAssertEqual(recipe.equipment, ["loaf pan"])
    }

    private func makeViewModel(mode: RecipeFormMode) -> RecipeFormViewModel {
        RecipeFormViewModel(
            mode: mode,
            createRecipeUseCase: NoOpCreateRecipeUseCase(),
            updateRecipeUseCase: NoOpUpdateRecipeUseCase(),
            fetchTagsUseCase: NoOpFetchTagsUseCase(),
            findOrCreateTagUseCase: NoOpFindOrCreateTagUseCase()
        )
    }
}
