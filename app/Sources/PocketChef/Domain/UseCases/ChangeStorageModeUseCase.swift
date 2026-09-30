import Foundation

enum StorageModeError: Error, Equatable {
    /// Switching to iCloud was refused because the account can't be used right now.
    case iCloudUnavailable(ICloudAccountStatus)
}

@MainActor
protocol ChangeStorageModeUseCase {
    var currentMode: StorageMode { get }
    func execute(_ mode: StorageMode) async throws
}

@MainActor
final class DefaultChangeStorageModeUseCase: ChangeStorageModeUseCase {
    private let switcher: StorageModeSwitcher
    private let accountStatusProvider: ICloudAccountStatusProvider

    init(switcher: StorageModeSwitcher, accountStatusProvider: ICloudAccountStatusProvider) {
        self.switcher = switcher
        self.accountStatusProvider = accountStatusProvider
    }

    var currentMode: StorageMode {
        switcher.currentMode
    }

    func execute(_ mode: StorageMode) async throws {
        guard mode != switcher.currentMode else { return }

        // Only the way up needs the account. Switching back to Local must work even after
        // the user signed out of iCloud, since that's when they most need their recipes local.
        if mode == .iCloud {
            let status = await accountStatusProvider.status()
            guard status == .available else {
                throw StorageModeError.iCloudUnavailable(status)
            }
        }

        try switcher.switchTo(mode)
    }
}
