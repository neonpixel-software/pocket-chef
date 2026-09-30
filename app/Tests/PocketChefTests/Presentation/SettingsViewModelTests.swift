@testable import PocketChef
import XCTest

@MainActor
private final class FakeChangeStorageModeUseCase: ChangeStorageModeUseCase {
    var currentMode: StorageMode = .local
    var error: Error?
    var executed: [StorageMode] = []

    func execute(_ mode: StorageMode) async throws {
        executed.append(mode)
        if let error { throw error }
        currentMode = mode
    }
}

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testStartsWithTheCurrentMode() {
        let useCase = FakeChangeStorageModeUseCase()
        useCase.currentMode = .iCloud

        let viewModel = SettingsViewModel(changeStorageModeUseCase: useCase, isICloudAvailableInBuild: true)

        XCTAssertEqual(viewModel.storageMode, .iCloud)
        XCTAssertTrue(viewModel.canChangeStorage)
    }

    func testSelectingAModeSwitchesAndClearsTheError() async {
        let useCase = FakeChangeStorageModeUseCase()
        let viewModel = SettingsViewModel(changeStorageModeUseCase: useCase, isICloudAvailableInBuild: true)

        await viewModel.selectStorageMode(.iCloud)

        XCTAssertEqual(useCase.executed, [.iCloud])
        XCTAssertEqual(viewModel.storageMode, .iCloud)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isSwitching)
    }

    func testSelectingTheCurrentModeDoesNothing() async {
        let useCase = FakeChangeStorageModeUseCase()
        let viewModel = SettingsViewModel(changeStorageModeUseCase: useCase, isICloudAvailableInBuild: true)

        await viewModel.selectStorageMode(.local)

        XCTAssertEqual(useCase.executed, [])
    }

    func testExplainsARefusalAndKeepsTheOldMode() async {
        let cases: [(ICloudAccountStatus, String)] = [
            (.noAccount, "Sign in to iCloud on this device to sync your recipes."),
            (.restricted, "iCloud is restricted on this device, so recipes can't sync."),
            (.temporarilyUnavailable, "iCloud is temporarily unavailable. Try again in a moment."),
            (.notConfiguredInBuild, "iCloud sync isn't available in this build."),
            (.couldNotDetermine, "Couldn't reach iCloud. Check your connection and try again."),
        ]
        for (status, message) in cases {
            let useCase = FakeChangeStorageModeUseCase()
            useCase.error = StorageModeError.iCloudUnavailable(status)
            let viewModel = SettingsViewModel(changeStorageModeUseCase: useCase, isICloudAvailableInBuild: true)

            await viewModel.selectStorageMode(.iCloud)

            XCTAssertEqual(viewModel.storageMode, .local, "\(status)")
            XCTAssertEqual(viewModel.errorMessage, message, "\(status)")
        }
    }

    func testShowsAGenericMessageWhenTheSwitchFails() async {
        let useCase = FakeChangeStorageModeUseCase()
        useCase.error = RecipeRepositoryError.recipeNotFound
        let viewModel = SettingsViewModel(changeStorageModeUseCase: useCase, isICloudAvailableInBuild: true)

        await viewModel.selectStorageMode(.iCloud)

        XCTAssertEqual(viewModel.storageMode, .local)
        XCTAssertEqual(viewModel.errorMessage, "Couldn't change where recipes are stored. Try again.")
    }

    func testCannotChangeStorageInABuildWithoutICloud() {
        let viewModel = SettingsViewModel(changeStorageModeUseCase: FakeChangeStorageModeUseCase(), isICloudAvailableInBuild: false)

        XCTAssertFalse(viewModel.canChangeStorage)
    }
}
