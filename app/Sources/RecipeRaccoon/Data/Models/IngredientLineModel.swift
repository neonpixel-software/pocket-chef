import Foundation
import SwiftData

@Model
final class IngredientLineModel {
    var id: UUID = UUID()
    var rawText: String = ""
    var amount: Double?
    var unit: String?
    var ingredientName: String?
    /// Index in the recipe's ingredient list. SwiftData doesn't keep the order of
    /// to-many relationships, so RecipeModel.toDomain() sorts by this.
    var position: Int = 0
    @Relationship(inverse: \RecipeModel.ingredients) var recipe: RecipeModel?

    init(
        id: UUID = UUID(),
        rawText: String,
        amount: Double? = nil,
        unit: String? = nil,
        ingredientName: String? = nil,
        position: Int = 0
    ) {
        self.id = id
        self.rawText = rawText
        self.amount = amount
        self.unit = unit
        self.ingredientName = ingredientName
        self.position = position
    }
}
