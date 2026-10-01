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

    private(set) var lastDensityRefresh: Date?
    private(set) var isRefreshingDensities = false
    private(set) var densityStatus: DensityRefreshStatus?

    private let changeStorageModeUseCase: ChangeStorageModeUseCase
    /// Nil in a build without the density API configuration (DensityAPI.xcconfig).
    private let refreshDensityCacheUseCase: RefreshDensityCacheUseCase?

    init(
        changeStorageModeUseCase: ChangeStorageModeUseCase,
        isICloudAvailableInBuild: Bool,
        refreshDensityCacheUseCase: RefreshDensityCacheUseCase? = nil
    ) {
        self.changeStorageModeUseCase = changeStorageModeUseCase
        self.isICloudAvailableInBuild = isICloudAvailableInBuild
        self.refreshDensityCacheUseCase = refreshDensityCacheUseCase
        storageMode = changeStorageModeUseCase.currentMode
        lastDensityRefresh = refreshDensityCacheUseCase?.lastRefresh
    }

    var isDensityAPIAvailableInBuild: Bool {
        refreshDensityCacheUseCase != nil
    }

    var canRefreshDensities: Bool {
        isDensityAPIAvailableInBuild && !isRefreshingDensities
    }

    /// Picks up a refresh that ran in the background since the screen was built.
    func reloadDensityStatus() {
        lastDensityRefresh = refreshDensityCacheUseCase?.lastRefresh
    }

    func refreshDensities() async {
        guard let refreshDensityCacheUseCase, !isRefreshingDensities else { return }

        isRefreshingDensities = true
        defer { isRefreshingDensities = false }

        do {
            let changes = try await refreshDensityCacheUseCase.execute()
            densityStatus = changes.isEmpty ? .upToDate : .updated
        } catch {
            print("Refreshing ingredient densities failed: \(error)")
            densityStatus = .failed
        }
        lastDensityRefresh = refreshDensityCacheUseCase.lastRefresh
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

/// The outcome of the last "Refresh Now" in Settings.
enum DensityRefreshStatus: Equatable {
    case upToDate
    case updated
    case failed

    var message: String {
        switch self {
        case .upToDate:
            String(localized: "Ingredient densities are up to date.")
        case .updated:
            String(localized: "Ingredient densities updated.")
        case .failed:
            String(localized: "Couldn't refresh ingredient densities. Check your connection and try again.")
        }
    }
}
