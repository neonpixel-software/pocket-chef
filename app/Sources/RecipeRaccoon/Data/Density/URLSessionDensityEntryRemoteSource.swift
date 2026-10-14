import Foundation

/// `GET /density-entries` on the density API, authenticated with the read key.
final class URLSessionDensityEntryRemoteSource: DensityEntryRemoteSource {
    private let configuration: DensityAPIConfiguration
    private let session: URLSession

    init(configuration: DensityAPIConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func fetchAll() async throws -> [DensityEntry] {
        var request = URLRequest(url: configuration.entriesURL)
        request.setValue(configuration.readKey, forHTTPHeaderField: "X-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw DensityEntryFetchError.requestFailed(underlying: error)
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            throw DensityEntryFetchError.httpStatus(status)
        }
        do {
            return try Self.decodeEntries(from: data)
        } catch {
            throw DensityEntryFetchError.invalidResponse(underlying: error)
        }
    }

    /// The API's `DensityEntryResponse`, serialized camelCase by ASP.NET.
    private struct EntryResponse: Decodable {
        let ingredientName: String
        let gramsPerMilliliter: Double
        let lastModifiedUtc: Date
    }

    static func decodeEntries(from data: Data) throws -> [DensityEntry] {
        let decoder = JSONDecoder()
        // .NET writes DateTimeOffset with 0–7 fractional digits ("…T12:34:56.1234567+00:00"),
        // which the plain .iso8601 strategy rejects.
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            guard let date = (try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(text))
                ?? (try? Date.ISO8601FormatStyle().parse(text)) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not an ISO 8601 date: \(text)")
            }
            return date
        }
        return try decoder.decode([EntryResponse].self, from: data).map {
            DensityEntry(ingredientName: $0.ingredientName, gramsPerMilliliter: $0.gramsPerMilliliter, lastModified: $0.lastModifiedUtc)
        }
    }
}
