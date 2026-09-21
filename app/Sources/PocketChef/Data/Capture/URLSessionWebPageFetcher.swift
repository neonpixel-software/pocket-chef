import Foundation

/// Not unit tested: a real network round trip isn't exercised in CI or this environment,
/// matching how FoundationModelsRecipeCaptureService's real AI call is treated. The size cap,
/// decoding, and plain-text conversion this delegates to (WebPageTextDecoding,
/// HTMLPlainTextConverter) are tested independently.
final class URLSessionWebPageFetcher: WebPageFetcher {
    func fetchPlainText(from url: URL) async throws -> String {
        let data: Data
        let encodingName: String?
        do {
            let (bytes, response) = try await URLSession.shared.bytes(from: url)
            encodingName = response.textEncodingName
            if response.expectedContentLength > Int64(WebPageTextDecoding.maxDownloadBytes) {
                throw WebPageFetchError.tooLarge
            }
            var buffer = Data()
            for try await byte in bytes {
                buffer.append(byte)
                if buffer.count > WebPageTextDecoding.maxDownloadBytes {
                    throw WebPageFetchError.tooLarge
                }
            }
            data = buffer
        } catch let error as WebPageFetchError {
            throw error
        } catch let error as URLError where error.code == .appTransportSecurityRequiresSecureConnection {
            throw WebPageFetchError.insecureConnection
        } catch {
            throw WebPageFetchError.requestFailed(underlying: error)
        }

        guard let html = WebPageTextDecoding.decode(data, declaredEncodingName: encodingName),
              let plainText = await HTMLPlainTextConverter.plainText(fromHTML: html) else {
            throw WebPageFetchError.emptyContent
        }
        return WebPageTextDecoding.truncated(plainText)
    }
}
