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
    func toDomain() -> Recipe {
        Recipe(
            id: UUID(),
            title: title,
            ingredients: ingredients.map { $0.toDomain() },
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
        } else if name.isEmpty, let candidateUnit {
            // The model sometimes puts the ingredient itself in the unit field ("yellow onion").
            name = candidateUnit
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
}
