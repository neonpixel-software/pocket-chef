import CoreData
@testable import PocketChef
import SwiftData
import XCTest

@MainActor
final class PersistenceControllerTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var notificationCenter: NotificationCenter!
    private var createdModes: [StorageMode] = []
    private var containers: [StorageMode: ModelContainer] = [:]

    override func setUp() {
        super.setUp()
        suiteName = "PersistenceControllerTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        notificationCenter = NotificationCenter()
        createdModes = []
        containers = [:]
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func makeController(isICloudEnabledInBuild: Bool = true) throws -> PersistenceController {
        try PersistenceController(
            defaults: defaults,
            isICloudEnabledInBuild: isICloudEnabledInBuild,
            notificationCenter: notificationCenter
        ) { [unowned self] mode in
            createdModes.append(mode)
            let container = try ModelContainer.inMemory()
            containers[mode] = container
            return container
        }
    }

    private func recipeTitles(_ controller: PersistenceController) throws -> [String] {
        try SwiftDataRecipeRepository(modelContext: controller.contextProvider.context).fetchAll().map(\.title)
    }

    private func addRecipe(_ title: String, to controller: PersistenceController) throws {
        let context = controller.contextProvider.context
        context.insert(RecipeModel(title: title, steps: [], isTypedSource: true))
        try context.save()
    }

    func testStartsLocalWhenNothingIsStored() throws {
        let controller = try makeController()

        XCTAssertEqual(controller.currentMode, .local)
        XCTAssertEqual(createdModes, [.local])
    }

    func testStartsInTheStoredMode() throws {
        defaults.set("iCloud", forKey: PersistenceController.storageModeKey)

        let controller = try makeController()

        XCTAssertEqual(controller.currentMode, .iCloud)
        XCTAssertEqual(createdModes, [.iCloud])
    }

    func testIgnoresAStoredICloudModeInABuildWithoutICloud() throws {
        defaults.set("iCloud", forKey: PersistenceController.storageModeKey)

        let controller = try makeController(isICloudEnabledInBuild: false)

        XCTAssertEqual(controller.currentMode, .local)
    }

    func testSeedsPresetTagsIntoTheOpenedStore() throws {
        let controller = try makeController()

        let tags = try SwiftDataTagRepository(modelContext: controller.contextProvider.context).fetchAll()
        XCTAssertEqual(tags.count, Tag.presetNames.count)
    }

    func testSwitchingToICloudCopiesLocalRecipesAndRetargetsTheContext() throws {
        let controller = try makeController()
        try addRecipe("Pancakes", to: controller)

        try controller.switchTo(.iCloud)

        XCTAssertEqual(controller.currentMode, .iCloud)
        XCTAssertEqual(defaults.string(forKey: PersistenceController.storageModeKey), "iCloud")
        XCTAssertEqual(try recipeTitles(controller), ["Pancakes"])
        XCTAssertEqual(createdModes, [.local, .iCloud])
    }

    func testSwitchingBackReplacesLocalWithTheICloudSnapshot() throws {
        let controller = try makeController()
        try addRecipe("Pancakes", to: controller)
        try controller.switchTo(.iCloud)
        let pancakes = try XCTUnwrap(SwiftDataRecipeRepository(modelContext: controller.contextProvider.context).fetchAll().first)
        try SwiftDataRecipeRepository(modelContext: controller.contextProvider.context).delete(id: pancakes.id)
        try addRecipe("Waffles", to: controller)

        try controller.switchTo(.local)

        XCTAssertEqual(controller.currentMode, .local)
        XCTAssertEqual(try recipeTitles(controller), ["Waffles"])
    }

    /// While in Local mode the reused iCloud container can import duplicate tags (remote changes
    /// are ignored then). Switching back must merge them before copying, so recipes end up on
    /// the row every device keeps (a preset first, then the smallest id).
    func testSwitchingBackToICloudMergesDuplicateTagsBeforeCopying() throws {
        let controller = try makeController()
        try controller.switchTo(.iCloud)
        try controller.switchTo(.local)
        let smallerID = try XCTUnwrap(UUID(uuidString: "11111111-0000-0000-0000-000000000000"))
        let largerID = try XCTUnwrap(UUID(uuidString: "99999999-0000-0000-0000-000000000000"))
        let iCloudContext = try XCTUnwrap(containers[.iCloud]).mainContext
        iCloudContext.insert(TagModel(id: largerID, name: "Brunch", isPreset: false))
        iCloudContext.insert(TagModel(id: smallerID, name: "Brunch", isPreset: false))
        try iCloudContext.save()
        let localContext = controller.contextProvider.context
        let brunch = TagModel(name: "brunch", isPreset: false)
        localContext.insert(RecipeModel(title: "Eggs Benedict", steps: [], isTypedSource: true, tags: [brunch]))
        try localContext.save()

        try controller.switchTo(.iCloud)

        let brunchTags = try iCloudContext.fetch(FetchDescriptor<TagModel>()).filter { $0.name.lowercased() == "brunch" }
        XCTAssertEqual(brunchTags.map(\.id), [smallerID])
        let recipe = try XCTUnwrap(SwiftDataRecipeRepository(modelContext: iCloudContext).fetchAll().first { $0.title == "Eggs Benedict" })
        XCTAssertEqual(recipe.tags.map(\.id), [smallerID])
    }

    func testSwitchingAgainReusesTheSessionsContainers() throws {
        let controller = try makeController()

        try controller.switchTo(.iCloud)
        try controller.switchTo(.local)
        try controller.switchTo(.iCloud)

        XCTAssertEqual(createdModes, [.local, .iCloud])
    }

    func testSwitchingToTheCurrentModeDoesNothing() throws {
        let controller = try makeController()
        let posted = expectation(forNotification: .recipeStoreDidChange, object: controller, notificationCenter: notificationCenter)
        posted.isInverted = true

        try controller.switchTo(.local)

        wait(for: [posted], timeout: 0.1)
        XCTAssertEqual(createdModes, [.local])
    }

    func testSwitchingPostsRecipeStoreDidChange() throws {
        let controller = try makeController()
        let posted = expectation(forNotification: .recipeStoreDidChange, object: controller, notificationCenter: notificationCenter)

        try controller.switchTo(.iCloud)

        wait(for: [posted], timeout: 1)
    }

    func testRemoteChangeInICloudModeMergesDuplicateTagsAndPostsAChange() throws {
        defaults.set("iCloud", forKey: PersistenceController.storageModeKey)
        let controller = try makeController()
        let context = controller.contextProvider.context
        context.insert(TagModel(name: "Breakfast", isPreset: true))
        try context.save()
        let posted = expectation(forNotification: .recipeStoreDidChange, object: controller, notificationCenter: notificationCenter)

        notificationCenter.post(name: .NSPersistentStoreRemoteChange, object: nil)

        wait(for: [posted], timeout: 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<TagModel>()), Tag.presetNames.count)
    }

    func testRemoteChangeInLocalModeIsIgnored() throws {
        let controller = try makeController()
        let posted = expectation(forNotification: .recipeStoreDidChange, object: controller, notificationCenter: notificationCenter)
        posted.isInverted = true

        notificationCenter.post(name: .NSPersistentStoreRemoteChange, object: nil)

        wait(for: [posted], timeout: 0.1)
    }
}
