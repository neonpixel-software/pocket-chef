import Foundation

extension DensityEntryModel {
    func toDomain() -> DensityEntry {
        DensityEntry(id: id, ingredientName: ingredientName, gramsPerMilliliter: gramsPerMilliliter)
    }
}

extension DensityEntry {
    func toModel() -> DensityEntryModel {
        DensityEntryModel(id: id, ingredientName: ingredientName, gramsPerMilliliter: gramsPerMilliliter)
    }
}
