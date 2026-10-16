@testable import RecipeRaccoon
import XCTest

final class LogTests: XCTestCase {
    func testSummarizesAFoundationErrorByTypeDomainAndCode() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError, userInfo: [NSFilePathErrorKey: "/Users/someone/recipe.txt"])

        XCTAssertEqual(error.logSummary, "NSError NSCocoaErrorDomain 260")
    }

    /// The summary is logged public, so it must never carry an associated value: a failed page
    /// fetch wraps an error whose description holds the recipe's URL.
    func testSummarizesASwiftErrorWithoutItsAssociatedValues() {
        let underlying = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: [NSURLErrorFailingURLStringErrorKey: "https://example.com/private-recipe"])
        let error = WebPageFetchError.requestFailed(underlying: underlying)

        XCTAssertTrue(error.logSummary.hasPrefix("WebPageFetchError RecipeRaccoon.WebPageFetchError "), error.logSummary)
        XCTAssertFalse(error.logSummary.contains("example.com"), error.logSummary)
    }
}
