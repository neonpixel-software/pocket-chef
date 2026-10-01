@testable import PocketChef
import XCTest

@MainActor
private final class FakeChangeStorageModeUseCase: ChangeStorageModeUseCase {
    var currentMode: StorageMode = .local

    func execute(_: StorageMode) async throws {}
}

@MainActor
private final class FakeRefreshDensityCacheUseCase: RefreshDensityCacheUseCase {
    var lastRefresh: Date?
    var result: Result<DensityCacheChanges, Error> = .success(DensityCacheChanges())
    var refreshDate = Date(timeIntervalSince1970: 1_790_000_000)
    private(set) var executeCount = 0

    func execute() async throws -> DensityCacheChanges {
        executeCount += 1
        let changes = try result.get()
        lastRefresh = refreshDate
        return changes
    }

    func executeIfStale() async throws -> DensityCacheChanges? {
        nil
    }
}

@MainActor
final class SettingsViewModelDensityTests: XCTestCase {
    private func makeViewModel(_ useCase: FakeRefreshDensityCacheUseCase?) -> SettingsViewModel {
        SettingsViewModel(
            changeStorageModeUseCase: FakeChangeStorageModeUseCase(),
            isICloudAvailableInBuild: true,
            refreshDensityCacheUseCase: useCase
        )
    }

    func testABuildWithoutTheDensityAPICannotRefresh() async {
        let viewModel = makeViewModel(nil)

        await viewModel.refreshDensities()

        XCTAssertFalse(viewModel.isDensityAPIAvailableInBuild)
        XCTAssertFalse(viewModel.canRefreshDensities)
        XCTAssertNil(viewModel.lastDensityRefresh)
        XCTAssertNil(viewModel.densityStatus)
    }

    func testStartsWithTheLastRefresh() {
        let useCase = FakeRefreshDensityCacheUseCase()
        useCase.lastRefresh = Date(timeIntervalSince1970: 5)

        let viewModel = makeViewModel(useCase)

        XCTAssertTrue(viewModel.canRefreshDensities)
        XCTAssertEqual(viewModel.lastDensityRefresh, Date(timeIntervalSince1970: 5))
    }

    func testRefreshReportsNewDataAndTheNewDate() async {
        let useCase = FakeRefreshDensityCacheUseCase()
        useCase.result = .success(DensityCacheChanges(added: 1))
        let viewModel = makeViewModel(useCase)

        await viewModel.refreshDensities()

        XCTAssertEqual(useCase.executeCount, 1)
        XCTAssertEqual(viewModel.densityStatus, .updated)
        XCTAssertEqual(viewModel.densityStatus?.message, "Ingredient densities updated.")
        XCTAssertEqual(viewModel.lastDensityRefresh, useCase.refreshDate)
        XCTAssertFalse(viewModel.isRefreshingDensities)
    }

    func testRefreshWithNoChangesSaysUpToDate() async {
        let viewModel = makeViewModel(FakeRefreshDensityCacheUseCase())

        await viewModel.refreshDensities()

        XCTAssertEqual(viewModel.densityStatus, .upToDate)
        XCTAssertEqual(viewModel.densityStatus?.message, "Ingredient densities are up to date.")
    }

    func testAFailedRefreshExplainsAndKeepsTheOldDate() async {
        let useCase = FakeRefreshDensityCacheUseCase()
        useCase.lastRefresh = Date(timeIntervalSince1970: 5)
        useCase.result = .failure(URLError(.notConnectedToInternet))
        let viewModel = makeViewModel(useCase)

        await viewModel.refreshDensities()

        XCTAssertEqual(viewModel.densityStatus, .failed)
        XCTAssertEqual(
            viewModel.densityStatus?.message,
            "Couldn't refresh ingredient densities. Check your connection and try again."
        )
        XCTAssertEqual(viewModel.lastDensityRefresh, Date(timeIntervalSince1970: 5))
    }

    func testReloadPicksUpABackgroundRefresh() {
        let useCase = FakeRefreshDensityCacheUseCase()
        let viewModel = makeViewModel(useCase)
        useCase.lastRefresh = Date(timeIntervalSince1970: 9)

        viewModel.reloadDensityStatus()

        XCTAssertEqual(viewModel.lastDensityRefresh, Date(timeIntervalSince1970: 9))
    }
}
