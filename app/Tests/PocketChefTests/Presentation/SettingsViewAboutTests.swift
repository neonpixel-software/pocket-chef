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
        XCTAssertNoThrow(try aboutLink().find(AboutView.self))
    }
    #else
    func testTheMacSettingsHaveNoAboutRow() {
        XCTAssertThrowsError(try aboutLink())
    }
    #endif

    private func aboutLink() throws -> InspectableView<ViewType.NavigationLink> {
        try sut.inspect().find(ViewType.NavigationLink.self) { try $0.labelView().text().string() == "About Pocket Chef" }
    }
}

@MainActor
private final class StubStorageModeUseCase: ChangeStorageModeUseCase {
    var currentMode: StorageMode = .local

    func execute(_: StorageMode) async throws { /* no-op: these tests don't switch storage */ }
}
