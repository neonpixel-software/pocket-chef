@testable import RecipeRaccoon
import SwiftUI
import ViewInspector
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

/// The welcome guide's storage choice: on the last page only, and the same switch as Settings.
@MainActor
final class WelcomeStorageChoiceViewTests: XCTestCase {
    private func makeSettings(
        useCase: FakeChangeStorageModeUseCase = FakeChangeStorageModeUseCase(),
        isICloudAvailableInBuild: Bool = true
    ) -> SettingsViewModel {
        SettingsViewModel(changeStorageModeUseCase: useCase, isICloudAvailableInBuild: isICloudAvailableInBuild)
    }

    func testOnlyTheLastPageShowsTheChoice() throws {
        let settings = makeSettings()
        let pages = WelcomeGuidePage.pages(isCaptureAvailable: true)

        let shown = try pages.map { page in
            try !WelcomeGuidePageView(page: page, accessibilityLabel: page.title, settingsViewModel: settings).inspect()
                .findAll(WelcomeStorageChoiceView.self).isEmpty
        }

        XCTAssertEqual(shown, [false, false, false, true])
    }

    func testWithoutSettingsTheLastPageHasNoChoice() throws {
        let page = try XCTUnwrap(WelcomeGuidePage.pages(isCaptureAvailable: true).last)

        let sut = WelcomeGuidePageView(page: page, accessibilityLabel: page.title)

        XCTAssertTrue(try sut.inspect().findAll(WelcomeStorageChoiceView.self).isEmpty)
    }

    /// The guide passes its settings view model down to the last page.
    func testTheGuideShowsTheChoiceOnItsLastPage() throws {
        let guide = WelcomeGuideViewModel(status: InMemoryWelcomeGuideStatus(hasSeen: false), isCaptureAvailable: { true })
        let sut = WelcomeGuideView(viewModel: guide, settingsViewModel: makeSettings()) {}

        XCTAssertEqual(try sut.inspect().findAll(WelcomeStorageChoiceView.self).count, 1)
    }

    func testStartsOnThisDeviceAndSaysSo() throws {
        let sut = WelcomeStorageChoiceView(viewModel: makeSettings())

        let picker = try sut.inspect().find(ViewType.Picker.self)
        XCTAssertEqual(try picker.selectedValue(StorageMode.self), .local)
        XCTAssertNoThrow(try sut.inspect().find(text: "Your recipes stay on this device. You can turn on iCloud later in Settings."))
    }

    func testChoosingICloudSwitchesLikeSettings() async throws {
        let useCase = FakeChangeStorageModeUseCase()
        let settings = makeSettings(useCase: useCase)
        let sut = WelcomeStorageChoiceView(viewModel: settings)

        try sut.inspect().find(ViewType.Picker.self).select(value: StorageMode.iCloud)
        try await waitUntil { settings.storageMode == .iCloud }

        XCTAssertEqual(useCase.executed, [.iCloud])
        XCTAssertNoThrow(try sut.inspect().find(text: "Your recipes sync to your other devices signed in to the same account."))
    }

    func testWithoutAnICloudAccountItShowsWhy() async throws {
        let useCase = FakeChangeStorageModeUseCase()
        useCase.error = StorageModeError.iCloudUnavailable(.noAccount)
        let settings = makeSettings(useCase: useCase)
        let sut = WelcomeStorageChoiceView(viewModel: settings)

        try sut.inspect().find(ViewType.Picker.self).select(value: StorageMode.iCloud)
        try await waitUntil { settings.errorMessage != nil }

        XCTAssertEqual(settings.storageMode, .local)
        XCTAssertNoThrow(try sut.inspect().find(text: "Sign in to iCloud on this device to sync your recipes."))
    }

    func testABuildWithoutICloudDisablesTheChoice() throws {
        let sut = WelcomeStorageChoiceView(viewModel: makeSettings(isICloudAvailableInBuild: false))

        XCTAssertTrue(try sut.inspect().find(ViewType.Picker.self).isDisabled())
        XCTAssertNoThrow(try sut.inspect().find(text: "iCloud sync isn't available in this build."))
    }

    /// The picker switches in a Task, as in Settings. Waits for it in real time rather than a
    /// fixed number of yields, and fails here rather than at a later, vaguer assertion.
    private func waitUntil(
        timeout: Duration = .seconds(2),
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async throws {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            guard ContinuousClock.now < deadline else {
                return XCTFail("Timed out waiting for the storage switch", file: file, line: line)
            }
            try await Task.sleep(for: .milliseconds(10))
        }
    }
}
