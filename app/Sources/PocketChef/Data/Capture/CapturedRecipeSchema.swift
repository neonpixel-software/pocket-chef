import Foundation
import FoundationModels

@Generable
struct CapturedRecipeSchema {
    @Guide(description: "A short, descriptive title for the recipe")
    let title: String
    @Guide(description: "Each ingredient as a separate structured line")
    let ingredients: [CapturedIngredientSchema]
    @Guide(description: "Each preparation step in order, one instruction per entry")
    let steps: [String]
}

@Generable
struct CapturedIngredientSchema {
    @Guide(description: "The ingredient exactly as written in the source text, e.g. '2 cups flour'")
    let rawText: String
    @Guide(description: "The quantity exactly as written (e.g. \"2\", \"1.5\", \"1/2\", \"1 1/2\", \"½\") if stated, else empty. Don't convert fractions")
    let amount: String
    @Guide(description: "Unit of measurement (e.g. \"cup\", \"tsp\", \"g\") if stated, else empty")
    let unit: String
    @Guide(description: "The ingredient's name alone, without quantity/unit, if identifiable, else empty")
    let ingredientName: String
}

extension CapturedRecipeSchema {
    /// Maps to a `Recipe`. With `source`, ingredients the model invented (neither the line
    /// nor the name appears in the source text) are dropped.
    func toDomain(source: String? = nil) -> Recipe {
        let grounded = source.map { source in
            ingredients.filter { IngredientDescriptors.appears(in: source, rawText: $0.rawText, name: $0.ingredientName) }
        } ?? ingredients
        return Recipe(
            id: UUID(),
            title: title,
            ingredients: grounded.map { $0.toDomain() },
            steps: steps
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty },
            source: .typed,
            tags: []
        )
    }
}

extension CapturedIngredientSchema {
    func toDomain() -> IngredientLine {
        let parsedAmount = IngredientAmountParser.parse(amount)
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        var name = ingredientName.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidateUnit = trimmedUnit.isEmpty ? parsedAmount?.unit : trimmedUnit
        var measurementUnit: String?
        if let candidateUnit, IngredientDescriptors.isMeasurementUnit(candidateUnit) {
            measurementUnit = candidateUnit
        } else {
            if name.isEmpty, let candidateUnit, !IngredientDescriptors.isPlaceholder(candidateUnit) {
                // The model sometimes puts the ingredient itself in the unit field ("yellow onion").
                name = candidateUnit
            }
            // The model also leaves the unit empty when the line has one ("1/3 cup butter").
            measurementUnit = unitWrittenInText(amountParsed: parsedAmount != nil)
        }
        name = IngredientDescriptors.removingSizeWords(from: name)
        return IngredientLine(
            id: UUID(),
            rawText: rawText,
            amount: parsedAmount?.value,
            unit: measurementUnit,
            ingredientName: name.isEmpty ? nil : name
        )
    }

    /// The unit as written in rawText right after the amount ("1/3 cup butter"), or at the end
    /// of an amount that isn't a number ("a pinch").
    private func unitWrittenInText(amountParsed: Bool) -> String? {
        let trimmedAmount = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAmount.isEmpty else { return nil }
        if !amountParsed, let unit = IngredientDescriptors.trailingUnit(in: trimmedAmount) {
            return unit
        }
        let line = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let range = line.range(of: trimmedAmount, options: [.anchored, .caseInsensitive]) else { return nil }
        return IngredientDescriptors.leadingUnit(in: String(line[range.upperBound...]))
    }
}
