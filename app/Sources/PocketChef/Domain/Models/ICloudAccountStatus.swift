import Foundation

/// The iCloud account state that decides whether a switch to iCloud storage can go ahead.
enum ICloudAccountStatus: Equatable {
    case available
    case noAccount
    case restricted
    case temporarilyUnavailable
    case couldNotDetermine
    /// This build has no iCloud entitlement (no signing team configured), so CloudKit can't be used at all.
    case notConfiguredInBuild
}
