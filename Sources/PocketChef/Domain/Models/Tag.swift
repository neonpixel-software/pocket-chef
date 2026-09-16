import Foundation

struct Tag: Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var isPreset: Bool

    /// The built-in preset tags shipped in-app, seeded on every launch. Single source of
    /// truth referenced by seeding code — see ModelContext.seedPresetTagsIfNeeded().
    static let presetNames = ["Breakfast", "Lunch", "Dinner", "Dessert", "Snack"]

    /// The name to display: presets are localized (matching/storage key stays the stable
    /// English name so FindOrCreateTagUseCase and existing SwiftData rows are unaffected);
    /// user-created or user-renamed tags always display exactly as typed, never translated.
    /// Resolves against the device's current locale, same as any other String(localized:) call.
    func localizedDisplayName() -> String {
        guard isPreset else { return name }
        switch name {
        case "Breakfast": return String(localized: "Breakfast")
        case "Lunch": return String(localized: "Lunch")
        case "Dinner": return String(localized: "Dinner")
        case "Dessert": return String(localized: "Dessert")
        case "Snack": return String(localized: "Snack")
        default: return name
        }
    }
}
