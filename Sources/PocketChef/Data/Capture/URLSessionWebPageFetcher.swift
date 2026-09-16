import Foundation

/// Not unit tested: a real network round trip isn't exercised in CI or this environment,
/// matching how FoundationModelsRecipeCaptureService's real AI call is treated. The plain-text
/// conversion this delegates to (HTMLPlainTextConverter) is tested independently.
final class URLSessionWebPageFetcher: WebPageFetcher {
    func fetchPlainText(from url: URL) async throws -> String {
        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(from: url)
        } catch {
            throw WebPageFetchError.requestFailed(underlying: error)
        }

        guard let html = String(data: data, encoding: .utf8),
              let plainText = HTMLPlainTextConverter.plainText(fromHTML: html) else {
            throw WebPageFetchError.emptyContent
        }
        return plainText
    }
}
