import Foundation

extension IngredientLineModel {
    func toDomain() -> IngredientLine {
        IngredientLine(
            id: id,
            rawText: rawText,
            amount: amount,
            unit: unit,
            ingredientName: ingredientName
        )
    }
}

extension IngredientLine {
    func toModel() -> IngredientLineModel {
        IngredientLineModel(
            id: id,
            rawText: rawText,
            amount: amount,
            unit: unit,
            ingredientName: ingredientName
        )
    }
}
