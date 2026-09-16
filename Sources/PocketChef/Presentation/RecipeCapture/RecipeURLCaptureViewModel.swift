import Foundation
import Observation

@Observable
@MainActor
final class RecipeURLCaptureViewModel {
    var urlText: String = ""
    private(set) var isCapturing = false
    private(set) var errorMessage: String?

    private let captureRecipeFromURLUseCase: CaptureRecipeFromURLUseCase

    init(captureRecipeFromURLUseCase: CaptureRecipeFromURLUseCase) {
        self.captureRecipeFromURLUseCase = captureRecipeFromURLUseCase
    }

    var canCapture: Bool {
        !urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @discardableResult
    func capture() async -> Recipe? {
        guard canCapture else { return nil }

        isCapturing = true
        defer { isCapturing = false }

        do {
            let recipe = try await captureRecipeFromURLUseCase.execute(urlString: urlText)
            errorMessage = nil
            return recipe
        } catch {
            print("Recipe URL capture failed: \(error)")
            if error is WebPageFetchError {
                errorMessage = "Couldn't load that page. Check the link and try again."
            } else {
                errorMessage = "Couldn't find a recipe on that page. Check it over and try again."
            }
            return nil
        }
    }
}
