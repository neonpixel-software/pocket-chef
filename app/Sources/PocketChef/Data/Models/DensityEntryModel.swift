import Foundation
import SwiftData

@Model
final class DensityEntryModel {
    var id: UUID = UUID()
    var ingredientName: String = ""
    var gramsPerCup: Double = 0

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
