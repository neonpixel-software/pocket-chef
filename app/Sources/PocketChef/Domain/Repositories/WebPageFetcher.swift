import Foundation

protocol WebPageFetcher: Sendable {
    func fetchPlainText(from url: URL) async throws -> String
}

enum WebPageFetchError: Error {
    case invalidURL
    case requestFailed(underlying: Error)
    case emptyContent
    case tooLarge
    case insecureConnection
}
