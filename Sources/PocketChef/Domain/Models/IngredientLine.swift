import Foundation

struct IngredientLine: Identifiable, Equatable {
    let id: UUID
    var rawText: String
    var amount: Double?
    var unit: String?
    var ingredientName: String?
}
