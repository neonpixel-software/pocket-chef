#if DEBUG
import Foundation
import SwiftData

/// A fixed starting state for the UI tests (Tests/PocketChefUITests), picked with the launch
/// arguments `-UITestScenario <name>`. The app then runs on an in-memory store, so a test run
/// never reads or changes the developer's recipes, and skips the density API.
enum UITestScenario: String {
    /// No recipes; the preset tags still show in the filter row.
    case empty
    /// One recipe without tags, and the list filtered by the Dinner tag, which matches nothing.
    case noMatchingTag
    /// Loading the recipes fails.
    case loadError

    static let launchArgument = "-UITestScenario"

    /// The Mac window's content size (below the toolbar) in a UI test run. macOS otherwise
    /// reopens the window at the size the last run left it, and layout checks need the same
    /// window every time: the header bug of #96 can't show in a window at its 168 pt minimum
    /// height, for one.
    static let macContentSize = CGSize(width: 900, height: 600)

    /// The scenario named in the launch arguments, or nil for a normal launch.
    static func current(arguments: [String] = ProcessInfo.processInfo.arguments) -> UITestScenario? {
        guard let index = arguments.firstIndex(of: launchArgument), arguments.indices.contains(index + 1) else {
            return nil
        }
        return UITestScenario(rawValue: arguments[index + 1])
    }

    /// The preset tag the list starts filtered by, if any.
    var selectedTagName: String? {
        self == .noMatchingTag ? "Dinner" : nil
    }

    /// Ignores the storage mode: there is no iCloud in a UI test run.
    @MainActor
    func makeContainer(for _: StorageMode) throws -> ModelContainer {
        let container = try ModelContainer(
            for: RecipeStore.schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        if self == .noMatchingTag {
            container.mainContext.insert(Recipe(
                id: UUID(),
                title: "Plain Toast",
                ingredients: [],
                steps: ["Toast the bread."],
                source: .typed,
                tags: []
            ).toModel())
            try container.mainContext.save()
        }
        return container
    }

    func recipeRepository(wrapping repository: RecipeRepository) -> RecipeRepository {
        self == .loadError ? FailingRecipeRepository() : repository
    }
}

/// A recipe repository whose reads fail, for the load-error state.
private struct FailingRecipeRepository: RecipeRepository {
    struct LoadError: LocalizedError {
        var errorDescription: String? {
            "The recipe store couldn't be read."
        }
    }

    func fetchAll() throws -> [Recipe] {
        throw LoadError()
    }

    func create(_: Recipe) throws { throw LoadError() }
    func update(_: Recipe) throws { throw LoadError() }
    func delete(id _: UUID) throws { throw LoadError() }
}
#endif
