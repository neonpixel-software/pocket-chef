import Foundation

protocol RecipeCaptureService: Sendable {
    func isAvailable() -> Bool
    func captureRecipe(from text: String) async throws -> Recipe
}

enum RecipeCaptureError: Error {
    case captureFailed
}
