@testable import PocketChef
import XCTest

@MainActor
private final class FakeStorageModeSwitcher: StorageModeSwitcher {
    var currentMode: StorageMode = .local
    var switchedTo: [StorageMode] = []
    var error: Error?

    func switchTo(_ mode: StorageMode) throws {
        if let error { throw error }
        switchedTo.append(mode)
        currentMode = mode
    }
}

private struct FakeAccountStatusProvider: ICloudAccountStatusProvider {
    let result: ICloudAccountStatus

    func status() async -> ICloudAccountStatus {
        result
    }
}

@MainActor
final class ChangeStorageModeUseCaseTests: XCTestCase {
    func testSwitchesToICloudWhenTheAccountIsAvailable() async throws {
        let switcher = FakeStorageModeSwitcher()
        let useCase = DefaultChangeStorageModeUseCase(switcher: switcher, accountStatusProvider: FakeAccountStatusProvider(result: .available))

        try await useCase.execute(.iCloud)

        XCTAssertEqual(switcher.switchedTo, [.iCloud])
        XCTAssertEqual(useCase.currentMode, .iCloud)
    }

    func testRefusesICloudWhenTheAccountIsUnavailable() async {
        let switcher = FakeStorageModeSwitcher()
        let useCase = DefaultChangeStorageModeUseCase(switcher: switcher, accountStatusProvider: FakeAccountStatusProvider(result: .noAccount))

        do {
            try await useCase.execute(.iCloud)
            XCTFail("Expected the switch to be refused")
        } catch {
            XCTAssertEqual(error as? StorageModeError, .iCloudUnavailable(.noAccount))
        }
        XCTAssertEqual(switcher.switchedTo, [])
    }

    func testSwitchingBackToLocalDoesNotNeedTheAccount() async throws {
        let switcher = FakeStorageModeSwitcher()
        switcher.currentMode = .iCloud
        let useCase = DefaultChangeStorageModeUseCase(switcher: switcher, accountStatusProvider: FakeAccountStatusProvider(result: .noAccount))

        try await useCase.execute(.local)

        XCTAssertEqual(switcher.switchedTo, [.local])
    }

    func testDoesNothingForTheCurrentMode() async throws {
        let switcher = FakeStorageModeSwitcher()
        let useCase = DefaultChangeStorageModeUseCase(switcher: switcher, accountStatusProvider: FakeAccountStatusProvider(result: .available))

        try await useCase.execute(.local)

        XCTAssertEqual(switcher.switchedTo, [])
    }

    func testPassesOnSwitchErrors() async {
        let switcher = FakeStorageModeSwitcher()
        switcher.error = RecipeRepositoryError.recipeNotFound
        let useCase = DefaultChangeStorageModeUseCase(switcher: switcher, accountStatusProvider: FakeAccountStatusProvider(result: .available))

        do {
            try await useCase.execute(.iCloud)
            XCTFail("Expected the switch error")
        } catch {
            XCTAssertEqual(error as? RecipeRepositoryError, .recipeNotFound)
        }
    }
}
