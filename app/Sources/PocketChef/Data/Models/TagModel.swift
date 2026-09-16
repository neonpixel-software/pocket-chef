import Foundation
import SwiftData

@Model
final class TagModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var isPreset: Bool
    @Relationship(inverse: \RecipeModel.tags) var recipes: [RecipeModel]?

    init(
        id: UUID = UUID(),
        name: String,
        isPreset: Bool
    ) {
        self.id = id
        self.name = name
        self.isPreset = isPreset
    }
}
