import Foundation

extension DensityEntryModel {
    func toDomain() -> DensityEntry {
        DensityEntry(ingredientName: ingredientName, gramsPerMilliliter: gramsPerMilliliter, lastModified: lastModified)
    }
}

extension DensityEntry {
    func toModel() -> DensityEntryModel {
        DensityEntryModel(ingredientName: ingredientName, gramsPerMilliliter: gramsPerMilliliter, lastModified: lastModified)
    }
}
