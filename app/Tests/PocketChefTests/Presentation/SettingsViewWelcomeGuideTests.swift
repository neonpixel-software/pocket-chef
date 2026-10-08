@testable import PocketChef
import SwiftUI
import ViewInspector
import XCTest

/// Settings → Show Welcome Guide (14.1).
@MainActor
final class SettingsViewWelcomeGuideTests: XCTestCase {
    private func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(changeStorageModeUseCase: StubChangeStorageModeUseCase(), isICloudAvailableInBuild: false)
    }

    #if os(iOS)
    func testShowWelcomeGuideAsksTheListToOpenIt() throws {
        var requests = 0
        let sut = SettingsView(viewModel: makeSettingsViewModel()) { requests += 1 }

        try sut.inspect().find(button: "Show Welcome Guide").tap()

        XCTAssertEqual(requests, 1)
    }

    func testWithoutAGuideThereIsNoButton() {
        let sut = SettingsView(viewModel: makeSettingsViewModel())

        XCTAssertThrowsError(try sut.inspect().find(button: "Show Welcome Guide"))
    }
    #else
    /// The Mac opens the guide's window itself, so the button is always there.
    func testTheMacAlwaysHasTheButton() throws {
        let sut = SettingsView(viewModel: makeSettingsViewModel())

        XCTAssertNoThrow(try sut.inspect().find(button: "Show Welcome Guide"))
    }
    #endif
}

@MainActor
private final class StubChangeStorageModeUseCase: ChangeStorageModeUseCase {
    var currentMode: StorageMode = .local

    func execute(_: StorageMode) async throws { /* no-op: these tests don't switch storage */ }
}
