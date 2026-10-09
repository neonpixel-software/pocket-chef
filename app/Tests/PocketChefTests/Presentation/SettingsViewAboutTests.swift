@testable import PocketChef
import SwiftUI
import ViewInspector
import XCTest

/// Settings → About Pocket Chef (14.2). The Mac has it in the app menu instead.
@MainActor
final class SettingsViewAboutTests: XCTestCase {
    private let sut = SettingsView(viewModel: SettingsViewModel(changeStorageModeUseCase: StubStorageModeUseCase(), isICloudAvailableInBuild: false))

    #if os(iOS)
    func testSettingsLinksToAbout() throws {
        let link = try sut.inspect().find(ViewType.NavigationLink.self) { try $0.labelView().text().string() == "About Pocket Chef" }

        XCTAssertNoThrow(try link.find(AboutView.self))
    }
    #else
    func testTheMacSettingsHaveNoAboutRow() {
        XCTAssertThrowsError(try sut.inspect().find(ViewType.NavigationLink.self))
    }
    #endif
}

@MainActor
private final class StubStorageModeUseCase: ChangeStorageModeUseCase {
    var currentMode: StorageMode = .local

    func execute(_: StorageMode) async throws { /* no-op: these tests don't switch storage */ }
}
