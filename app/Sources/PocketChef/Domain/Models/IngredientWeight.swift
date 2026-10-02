import Foundation

/// An ingredient line's weight, or why it has none.
enum IngredientWeight: Equatable {
    case grams(Double)
    case unavailable(Reason)

    enum Reason: Equatable {
        /// No amount to convert ("salt to taste").
        case noAmount
        /// No unit, or one without a fixed size ("3 eggs", "2 cloves garlic", "a pinch").
        case noMeasurementUnit
        /// A volume, but no cached density for the ingredient (PLAN.md 11.2).
        case noDensity
    }

    /// Weighs one line. Weight units convert directly; volumes need the ingredient's density.
    static func of(_ line: IngredientLine, density: DensityEntry?, standard: VolumeStandard) -> IngredientWeight {
        guard let amount = line.amount, amount > 0 else { return .unavailable(.noAmount) }
        guard let unit = line.unit, let kind = MeasurementUnits.kind(of: unit, standard: standard) else {
            return .unavailable(.noMeasurementUnit)
        }
        switch kind {
        case let .weight(grams):
            return .grams(amount * grams)
        case let .volume(milliliters):
            guard let density else { return .unavailable(.noDensity) }
            return .grams(amount * milliliters * density.gramsPerMilliliter)
        }
    }
}
