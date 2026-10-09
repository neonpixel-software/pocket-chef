#if DEBUG
import CoreGraphics
import Foundation
import ImageIO
import SwiftData
import UniformTypeIdentifiers

/// A fixed starting state for the UI tests (Tests/PocketChefUITests), picked with the launch
/// arguments `-UITestScenario <name>`. The app then runs on an in-memory store, so a test run
/// never reads or changes the developer's recipes, and skips the density API.
enum UITestScenario: String, CaseIterable {
    /// No recipes; the preset tags still show in the filter row.
    case empty
    /// One recipe without tags, and the list filtered by the Dinner tag, which matches nothing.
    case noMatchingTag
    /// Loading the recipes fails.
    case loadError
    /// 40 recipes ("Recipe 01" to "Recipe 40"), far more than fit, so the list scrolls.
    case manyRecipes
    /// Opens on the detail screen of one recipe (no tags), as if tapped from the list: clicks
    /// don't reach the app on GitHub's macOS runner, so a test can't navigate there.
    case recipeDetail
    /// One recipe ("Rainbow Salad") with three photos in solid colors, red (the cover), green
    /// and blue, so a screenshot shows which photo is where.
    case recipeWithPhotos
    /// The recipeWithPhotos recipe, opened on its detail screen like recipeDetail.
    case recipeWithPhotosDetail
    /// No recipes, and the welcome guide opens as on a first launch. No other scenario shows it.
    case welcomeGuide

    static let launchArgument = "-UITestScenario"

    /// The Mac window's content size (below the toolbar) in a UI test run. macOS otherwise
    /// reopens the window at the size the last run left it, and layout checks need the same
    /// window every time: the header bug of #96 can't show in a window at its 168 pt minimum
    /// height, for one.
    static let macContentSize = CGSize(width: 900, height: 600)

    /// The scenario named in the launch arguments, or nil for a normal launch. Stops the app on
    /// an unknown or missing name: running on, a test would check the developer's own store.
    static func current(arguments: [String] = ProcessInfo.processInfo.arguments) -> UITestScenario? {
        guard let index = arguments.firstIndex(of: launchArgument) else { return nil }
        let name = arguments.indices.contains(index + 1) ? arguments[index + 1] : ""
        guard let scenario = UITestScenario(rawValue: name) else {
            fatalError("Unknown \(launchArgument) \"\(name)\"; expected one of \(allCases.map(\.rawValue))")
        }
        return scenario
    }

    /// Whether the app opens on the first recipe's detail screen instead of the list.
    var opensRecipeDetail: Bool {
        self == .recipeDetail || self == .recipeWithPhotosDetail
    }

    /// Whether the welcome guide opens at launch.
    var showsWelcomeGuide: Bool {
        self == .welcomeGuide
    }

    /// The preset tag the list starts filtered by, if any.
    var selectedTagName: String? {
        self == .noMatchingTag ? "Dinner" : nil
    }

    /// Ignores the storage mode: there is no iCloud in a UI test run.
    @MainActor
    func makeContainer(for _: StorageMode) throws -> ModelContainer {
        let container = try RecipeStore.makeInMemoryContainer()
        for title in recipeTitles {
            container.mainContext.insert(Recipe(
                id: UUID(),
                title: title,
                ingredients: [],
                steps: ["Serve."],
                source: .typed,
                tags: []
            ).toModel())
        }
        if self == .recipeWithPhotos || self == .recipeWithPhotosDetail {
            try Self.insertRecipeWithPhotos(into: container.mainContext)
        }
        try container.mainContext.save()
        return container
    }

    struct PhotoColor {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
    }

    /// Red, green and blue, in gallery order.
    static let photoColors = [
        PhotoColor(red: 0.9, green: 0.1, blue: 0.1),
        PhotoColor(red: 0.1, green: 0.7, blue: 0.2),
        PhotoColor(red: 0.1, green: 0.3, blue: 0.9),
    ]

    private static func insertRecipeWithPhotos(into context: ModelContext) throws {
        let photos = try photoColors.map { color in try (RecipePhoto(id: UUID()), solidJPEG(color)) }
        let recipe = Recipe(
            id: UUID(),
            title: "Rainbow Salad",
            ingredients: [],
            steps: ["Serve."],
            source: .typed,
            tags: [],
            photos: photos.map(\.0)
        )
        let newPhotos = Dictionary(uniqueKeysWithValues: photos.map { photo, data in
            (photo.id, ProcessedPhoto(imageData: data, thumbnailData: data))
        })
        try SwiftDataRecipeRepository(modelContext: context).create(recipe, newPhotos: newPhotos)
    }

    /// A 400 × 300 JPEG in one color: generated, so the app bundle carries no test images.
    private static func solidJPEG(_ color: PhotoColor) throws -> Data {
        struct EncodingFailed: Error {}
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: 400,
                  height: 300,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: space,
                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
              ) else { throw EncodingFailed() }
        context.setFillColor(CGColor(srgbRed: color.red, green: color.green, blue: color.blue, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 400, height: 300))
        let data = NSMutableData()
        guard let image = context.makeImage(),
              let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw EncodingFailed()
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw EncodingFailed() }
        return data as Data
    }

    private var recipeTitles: [String] {
        switch self {
        case .empty, .loadError, .welcomeGuide: []
        case .noMatchingTag: ["Plain Toast"]
        case .manyRecipes: (1...40).map { String(format: "Recipe %02d", $0) }
        case .recipeDetail: ["Plain Toast"]
        case .recipeWithPhotos, .recipeWithPhotosDetail: []
        }
    }

    func recipeRepository(wrapping repository: RecipeRepository) -> RecipeRepository {
        self == .loadError ? FailingRecipeRepository() : repository
    }
}

/// A recipe repository where every call fails, for the load-error state. That state only
/// reads; the writes fail too rather than pretend to save.
private struct FailingRecipeRepository: RecipeRepository {
    struct LoadError: LocalizedError {
        var errorDescription: String? {
            "The recipe store couldn't be read."
        }
    }

    func fetchAll() throws -> [Recipe] {
        throw LoadError()
    }

    func create(_: Recipe, newPhotos _: [UUID: ProcessedPhoto]) throws { throw LoadError() }
    func update(_: Recipe, newPhotos _: [UUID: ProcessedPhoto]) throws { throw LoadError() }
    func delete(id _: UUID) throws { throw LoadError() }
}
#endif
