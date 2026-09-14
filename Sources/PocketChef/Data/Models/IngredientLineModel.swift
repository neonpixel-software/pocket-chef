import Foundation
import SwiftData

@Model
final class IngredientLineModel {
    @Attribute(.unique) var id: UUID
    var rawText: String
    var amount: Double?
    var unit: String?
    var ingredientName: String?

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
