@testable import PocketChef
import XCTest

/// Answers every request from `handler` instead of the network, and records the request.
private final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    nonisolated(unsafe) static var lastRequest: URLRequest?

    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lastRequest = request
        do {
            guard let handler = Self.handler else { throw URLError(.unknown) }
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class URLSessionDensityEntryRemoteSourceTests: XCTestCase {
    private let configuration = DensityAPIConfiguration(host: "density.example.com", readKey: "read-key")!

    override func tearDown() {
        StubURLProtocol.handler = nil
        StubURLProtocol.lastRequest = nil
        super.tearDown()
    }

    private func makeSource() -> URLSessionDensityEntryRemoteSource {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [StubURLProtocol.self]
        return URLSessionDensityEntryRemoteSource(configuration: configuration, session: URLSession(configuration: sessionConfiguration))
    }

    private func respond(status: Int, body: String) {
        StubURLProtocol.handler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!, Data(body.utf8))
        }
    }

    func testFetchAllSendsTheReadKeyToTheEntriesEndpoint() async throws {
        respond(status: 200, body: "[]")

        _ = try await makeSource().fetchAll()

        let request = try XCTUnwrap(StubURLProtocol.lastRequest)
        XCTAssertEqual(request.url?.absoluteString, "https://density.example.com/density-entries")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Api-Key"), "read-key")
    }

    func testFetchAllDecodesTheAPIResponse() async throws {
        respond(status: 200, body: """
        [
          {"ingredientName":"flour","gramsPerMilliliter":0.53,"lastModifiedUtc":"2026-09-28T12:34:56.1234567+00:00"},
          {"ingredientName":"honey","gramsPerMilliliter":1.42,"lastModifiedUtc":"2026-09-28T12:34:56+00:00"}
        ]
        """)

        let entries = try await makeSource().fetchAll()

        XCTAssertEqual(entries.map(\.ingredientName), ["flour", "honey"])
        XCTAssertEqual(entries.map(\.gramsPerMilliliter), [0.53, 1.42])
        XCTAssertEqual(entries[0].lastModified.timeIntervalSince1970, 1_790_598_896.1234567, accuracy: 0.001)
        XCTAssertEqual(entries[1].lastModified.timeIntervalSince1970, 1_790_598_896)
    }

    func testDecodingAcceptsEveryFractionalSecondLengthDotNetWrites() throws {
        for fraction in ["", ".1", ".123", ".123456", ".1234567"] {
            let json = #"[{"ingredientName":"a","gramsPerMilliliter":1,"lastModifiedUtc":"2026-09-28T12:34:56\#(fraction)+00:00"}]"#

            let entries = try URLSessionDensityEntryRemoteSource.decodeEntries(from: Data(json.utf8))

            XCTAssertEqual(entries.first?.lastModified.timeIntervalSince1970 ?? 0, 1_790_598_896, accuracy: 1, "fraction \(fraction)")
        }
    }

    func testFetchAllReportsANonSuccessStatus() async {
        respond(status: 401, body: "")

        do {
            _ = try await makeSource().fetchAll()
            XCTFail("Expected an error")
        } catch let DensityEntryFetchError.httpStatus(status) {
            XCTAssertEqual(status, 401)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchAllReportsAMalformedBody() async {
        respond(status: 200, body: #"{"error":"nope"}"#)

        do {
            _ = try await makeSource().fetchAll()
            XCTFail("Expected an error")
        } catch DensityEntryFetchError.invalidResponse {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchAllReportsBeingOffline() async {
        StubURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }

        do {
            _ = try await makeSource().fetchAll()
            XCTFail("Expected an error")
        } catch let DensityEntryFetchError.requestFailed(underlying) {
            XCTAssertEqual((underlying as? URLError)?.code, .notConnectedToInternet)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
