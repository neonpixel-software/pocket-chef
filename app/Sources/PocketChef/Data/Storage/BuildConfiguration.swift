import Foundation

enum BuildConfiguration {
    /// Whether this build carries the iCloud entitlement. It's set by the gitignored
    /// app/Config/Signing.xcconfig (see Signing.xcconfig.example); CI and fresh clones build
    /// without it. CloudKit raises an Objective-C exception when the entitlement is missing,
    /// so nothing may touch CloudKit unless this is true.
    static var isICloudEnabled: Bool {
        #if ICLOUD_ENABLED
        true
        #else
        false
        #endif
    }
}
