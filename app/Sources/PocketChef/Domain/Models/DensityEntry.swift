import Foundation

struct DensityEntry: Identifiable, Equatable {
    let id: UUID
    var ingredientName: String
    var gramsPerMilliliter: Double
}
