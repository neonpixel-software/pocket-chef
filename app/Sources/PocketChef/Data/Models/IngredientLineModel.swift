import Foundation
import SwiftData

@Model
final class IngredientLineModel {
    var id: UUID = UUID()
    var rawText: String = ""
    var amount: Double?
    var unit: String?
    var ingredientName: String?
    @Relationship(inverse: \RecipeModel.ingredients) var recipe: RecipeModel?

    init(
        id: UUID = UUID(),
        rawText: String,
        amount: Double? = nil,
        unit: String? = nil,
        ingredientName: String? = nil
    ) {
        self.id = id
        self.rawText = rawText
        self.amount = amount
        self.unit = unit
        self.ingredientName = ingredientName
    }
}
