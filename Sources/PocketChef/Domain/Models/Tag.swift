import Foundation

struct Tag: Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var isPreset: Bool

    /// The built-in preset tags shipped in-app, seeded on every launch. Single source of
    /// truth referenced by seeding code — see ModelContext.seedPresetTagsIfNeeded().
    static let presetNames = ["Breakfast", "Lunch", "Dinner", "Dessert", "Snack"]
}
