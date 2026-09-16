import Foundation

protocol CaptureRecipeUseCase: Sendable {
    func execute(text: String) async throws -> Recipe
}

final class DefaultCaptureRecipeUseCase: CaptureRecipeUseCase {
    private let captureService: RecipeCaptureService

    init(captureService: RecipeCaptureService) {
        self.captureService = captureService
    }

    func execute(text: String) async throws -> Recipe {
        try await captureService.captureRecipe(from: text)
    }
}
