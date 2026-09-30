import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    private(set) var storageMode: StorageMode
    private(set) var isSwitching = false
    private(set) var errorMessage: String?
    /// False in a build without the iCloud entitlement (CI, a clone without Signing.xcconfig).
    let isICloudAvailableInBuild: Bool

    private let changeStorageModeUseCase: ChangeStorageModeUseCase

    init(changeStorageModeUseCase: ChangeStorageModeUseCase, isICloudAvailableInBuild: Bool) {
        self.changeStorageModeUseCase = changeStorageModeUseCase
        self.isICloudAvailableInBuild = isICloudAvailableInBuild
        storageMode = changeStorageModeUseCase.currentMode
    }

    var canChangeStorage: Bool {
        isICloudAvailableInBuild && !isSwitching
    }

    func selectStorageMode(_ mode: StorageMode) async {
        guard mode != storageMode, !isSwitching else { return }

        isSwitching = true
        defer { isSwitching = false }

        do {
            try await changeStorageModeUseCase.execute(mode)
            storageMode = mode
            errorMessage = nil
        } catch let StorageModeError.iCloudUnavailable(status) {
            errorMessage = Self.message(for: status)
        } catch {
            print("Switching storage mode failed: \(error)")
            errorMessage = String(localized: "Couldn't change where recipes are stored. Try again.")
        }
    }

    private static func message(for status: ICloudAccountStatus) -> String {
        switch status {
        case .noAccount:
            String(localized: "Sign in to iCloud on this device to sync your recipes.")
        case .restricted:
            String(localized: "iCloud is restricted on this device, so recipes can't sync.")
        case .temporarilyUnavailable:
            String(localized: "iCloud is temporarily unavailable. Try again in a moment.")
        case .notConfiguredInBuild:
            String(localized: "iCloud sync isn't available in this build.")
        case .available, .couldNotDetermine:
            String(localized: "Couldn't reach iCloud. Check your connection and try again.")
        }
    }
}
