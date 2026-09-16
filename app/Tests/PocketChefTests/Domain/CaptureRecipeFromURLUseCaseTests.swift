import XCTest
@testable import PocketChef

private final class FakeWebPageFetcher: WebPageFetcher, @unchecked Sendable {
    var result: Result<String, Error>
    private(set) var requestedURL: URL?

    init(result: Result<String, Error>) {
        self.result = result
    }

    func fetchPlainText(from url: URL) async throws -> String {
        requestedURL = url
        return try result.get()
    }
}

private struct FakeCaptureRecipeUseCase: CaptureRecipeUseCase {
    var result: Result<Recipe, Error>

    func execute(text: String) async throws -> Recipe {
        try result.get()
    }
}

private struct CaptureFailure: Error, Equatable {}

final class CaptureRecipeFromURLUseCaseTests: XCTestCase {
    func testExecuteThrowsInvalidURLWithoutFetchingWhenURLStringIsMalformed() async {
        let fetcher = FakeWebPageFetcher(result: .success("irrelevant"))
        let useCase = DefaultCaptureRecipeFromURLUseCase(
            webPageFetcher: fetcher,
            captureRecipeUseCase: FakeCaptureRecipeUseCase(result: .success(makeRecipe()))
        )

        do {
            _ = try await useCase.execute(urlString: "not a url")
            XCTFail("Expected invalidURL to be thrown")
        } catch WebPageFetchError.invalidURL {
            XCTAssertNil(fetcher.requestedURL)
        } catch {
            XCTFail("Expected WebPageFetchError.invalidURL, got \(error)")
        }
    }

    func testExecuteThrowsInvalidURLForNonHTTPScheme() async {
        let fetcher = FakeWebPageFetcher(result: .success("irrelevant"))
        let useCase = DefaultCaptureRecipeFromURLUseCase(
            webPageFetcher: fetcher,
            captureRecipeUseCase: FakeCaptureRecipeUseCase(result: .success(makeRecipe()))
        )

        do {
            _ = try await useCase.execute(urlString: "ftp://example.com/recipe")
            XCTFail("Expected invalidURL to be thrown")
        } catch WebPageFetchError.invalidURL {
            // expected
        } catch {
            XCTFail("Expected WebPageFetchError.invalidURL, got \(error)")
        }
    }

    func testExecutePropagatesFetcherError() async {
        let fetcher = FakeWebPageFetcher(result: .failure(WebPageFetchError.emptyContent))
        let useCase = DefaultCaptureRecipeFromURLUseCase(
            webPageFetcher: fetcher,
            captureRecipeUseCase: FakeCaptureRecipeUseCase(result: .success(makeRecipe()))
        )

        do {
            _ = try await useCase.execute(urlString: "https://example.com/recipe")
            XCTFail("Expected error to be thrown")
        } catch WebPageFetchError.emptyContent {
            // expected
        } catch {
            XCTFail("Expected WebPageFetchError.emptyContent, got \(error)")
        }
    }

    func testExecutePropagatesCaptureRecipeUseCaseError() async {
        let fetcher = FakeWebPageFetcher(result: .success("Pancakes\n2 eggs\nMix well"))
        let useCase = DefaultCaptureRecipeFromURLUseCase(
            webPageFetcher: fetcher,
            captureRecipeUseCase: FakeCaptureRecipeUseCase(result: .failure(CaptureFailure()))
        )

        do {
            _ = try await useCase.execute(urlString: "https://example.com/recipe")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is CaptureFailure)
        }
    }

    func testExecuteFetchesPlainTextAndSetsSourceToURLOnSuccess() async throws {
        let fetcher = FakeWebPageFetcher(result: .success("Pancakes\n2 eggs\nMix well"))
        let capturedRecipe = makeRecipe(source: .typed)
        let useCase = DefaultCaptureRecipeFromURLUseCase(
            webPageFetcher: fetcher,
            captureRecipeUseCase: FakeCaptureRecipeUseCase(result: .success(capturedRecipe))
        )

        let result = try await useCase.execute(urlString: "https://example.com/recipe")

        XCTAssertEqual(fetcher.requestedURL, URL(string: "https://example.com/recipe"))
        XCTAssertEqual(result.title, capturedRecipe.title)
        XCTAssertEqual(result.source, .url(URL(string: "https://example.com/recipe")!))
    }

    private func makeRecipe(title: String = "Pancakes", source: RecipeSource = .typed) -> Recipe {
        Recipe(id: UUID(), title: title, ingredients: [], steps: [], source: source, tags: [])
    }
}
