import Foundation
import SwiftData

@Model
final class DensityEntryModel {
    var id: UUID = UUID()
    var ingredientName: String = ""
    var gramsPerMilliliter: Double = 0

    init(
        id: UUID = UUID(),
        ingredientName: String,
        gramsPerMilliliter: Double
    ) {
        self.id = id
        self.ingredientName = ingredientName
        self.gramsPerMilliliter = gramsPerMilliliter
    }
}
