import Foundation

/// Moves the app's recipes between the Local and iCloud stores and makes the target the
/// store every repository reads from. Switching up merges local recipes into iCloud;
/// switching back replaces the local store with a snapshot of iCloud.
@MainActor
protocol StorageModeSwitcher: AnyObject {
    var currentMode: StorageMode { get }
    func switchTo(_ mode: StorageMode) throws
}
