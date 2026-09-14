import Foundation

extension TagModel {
    func toDomain() -> Tag {
        Tag(id: id, name: name, isPreset: isPreset)
    }
}

extension Tag {
    func toModel() -> TagModel {
        TagModel(id: id, name: name, isPreset: isPreset)
    }
}
