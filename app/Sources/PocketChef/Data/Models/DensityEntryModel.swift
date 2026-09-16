import Foundation
import SwiftData

@Model
final class DensityEntryModel {
    @Attribute(.unique) var id: UUID
    var ingredientName: String
    var gramsPerCup: Double

    init(
        id: UUID = UUID(),
        ingredientName: String,
        gramsPerCup: Double
    ) {
        self.id = id
        self.ingredientName = ingredientName
        self.gramsPerCup = gramsPerCup
    }
}
