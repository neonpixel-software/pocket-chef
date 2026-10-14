import Foundation

/// Where this device keeps its recipes. The choice is per device and never synced:
/// a new device starts on `.local` and each device opts into iCloud separately.
enum StorageMode: String, CaseIterable {
    case local
    case iCloud
}
