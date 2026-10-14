#if DEBUG
import Foundation

/// Lets SwiftUI previews render capture-related UI without touching FoundationModels.
struct PreviewRecipeCaptureService: RecipeCaptureService {
    func isAvailable() -> Bool { true }

    func captureRecipe(from _: String) async throws -> Recipe {
        SampleData.recipes[0]
    }
}
#endif
