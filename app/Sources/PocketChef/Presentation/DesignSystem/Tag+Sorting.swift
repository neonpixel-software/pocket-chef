import Foundation

extension [Tag] {
    /// Presets first (alphabetical), then custom tags (alphabetical) — the display order
    /// used everywhere tags are picked or filtered.
    func sortedPresetsFirst() -> [Tag] {
        sorted { lhs, rhs in
            if lhs.isPreset != rhs.isPreset { return lhs.isPreset }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}
