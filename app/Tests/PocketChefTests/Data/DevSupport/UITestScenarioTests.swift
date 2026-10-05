@testable import PocketChef
import SwiftData
import XCTest

final class UITestScenarioTests: XCTestCase {
    func testCurrentIsNilForANormalLaunch() {
        XCTAssertNil(UITestScenario.current(arguments: ["PocketChef", "-AppleLanguages", "(en)"]))
    }

    func testCurrentReadsTheNameAfterTheArgument() {
        for scenario in UITestScenario.allCases {
            let arguments = ["PocketChef", "-UITestScenario", scenario.rawValue, "-AppleLanguages", "(en)"]
            XCTAssertEqual(UITestScenario.current(arguments: arguments), scenario)
        }
    }

    @MainActor
    func testEachScenarioStartsWithItsRecipes() throws {
        let expectedCounts: [UITestScenario: Int] = [.empty: 0, .noMatchingTag: 1, .loadError: 0, .manyRecipes: 40]
        for scenario in UITestScenario.allCases {
            let container = try scenario.makeContainer(for: .local)
            let count = try container.mainContext.fetchCount(FetchDescriptor<RecipeModel>())
            XCTAssertEqual(count, expectedCounts[scenario], "\(scenario)")
        }
    }

    func testOnlyTheLoadErrorScenarioFailsToLoad() throws {
        let container = try ModelContainer(
            for: RecipeStore.schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        let repository = SwiftDataRecipeRepository(modelContext: ModelContext(container))
        for scenario in UITestScenario.allCases {
            let wrapped = scenario.recipeRepository(wrapping: repository)
            if scenario == .loadError {
                XCTAssertThrowsError(try wrapped.fetchAll())
            } else {
                XCTAssertNoThrow(try wrapped.fetchAll(), "\(scenario)")
            }
        }
    }
}
