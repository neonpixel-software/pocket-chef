@testable import PocketChef
import XCTest

private struct FakeRecipeCaptureService: RecipeCaptureService {
    var isAvailableResult: Bool

    func isAvailable() -> Bool { isAvailableResult }

    func captureRecipe(from _: String) async throws -> Recipe {
        Recipe(id: UUID(), title: "", ingredients: [], steps: [], source: .typed, tags: [])
    }
}

final class CheckCaptureAvailabilityUseCaseTests: XCTestCase {
    func testExecuteReturnsTrueWhenServiceIsAvailable() {
        let useCase = DefaultCheckCaptureAvailabilityUseCase(captureService: FakeRecipeCaptureService(isAvailableResult: true))

        XCTAssertTrue(useCase.execute())
    }

    func testExecuteReturnsFalseWhenServiceIsUnavailable() {
        let useCase = DefaultCheckCaptureAvailabilityUseCase(captureService: FakeRecipeCaptureService(isAvailableResult: false))

        XCTAssertFalse(useCase.execute())
    }
}
