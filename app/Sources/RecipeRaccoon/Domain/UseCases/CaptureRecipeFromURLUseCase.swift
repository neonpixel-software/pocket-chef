import Foundation

protocol CaptureRecipeFromURLUseCase: Sendable {
    func execute(urlString: String) async throws -> Recipe
}

final class DefaultCaptureRecipeFromURLUseCase: CaptureRecipeFromURLUseCase {
    private let webPageFetcher: WebPageFetcher
    private let captureRecipeUseCase: CaptureRecipeUseCase

    init(webPageFetcher: WebPageFetcher, captureRecipeUseCase: CaptureRecipeUseCase) {
        self.webPageFetcher = webPageFetcher
        self.captureRecipeUseCase = captureRecipeUseCase
    }

    func execute(urlString: String) async throws -> Recipe {
        guard let url = URL(string: urlString), let scheme = url.scheme, scheme.hasPrefix("http") else {
            throw WebPageFetchError.invalidURL
        }
        let plainText = try await webPageFetcher.fetchPlainText(from: url)
        var recipe = try await captureRecipeUseCase.execute(text: plainText)
        recipe.source = .url(url)
        return recipe
    }
}
