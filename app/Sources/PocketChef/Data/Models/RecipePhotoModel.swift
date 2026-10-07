import Foundation
import SwiftData

@Model
final class RecipePhotoModel {
    var id: UUID = UUID()
    /// Index in the recipe's gallery; 0 is the cover. SwiftData doesn't keep the order of
    /// to-many relationships, so RecipeModel.toDomain() sorts by this, then by id.
    /// Not unique, on purpose: CloudKit-backed stores can't have unique constraints (#48), and
    /// two devices reordering one gallery offline can leave duplicates until the next save.
    var position: Int = 0
    /// External storage keeps the bytes out of the store's rows; CloudKit syncs them as assets.
    @Attribute(.externalStorage) var imageData: Data?
    @Attribute(.externalStorage) var thumbnailData: Data?
    @Relationship(inverse: \RecipeModel.photos) var recipe: RecipeModel?

    /// False while the bytes aren't on this device, e.g. a synced row whose assets haven't arrived.
    var hasBytes: Bool {
        imageData != nil && thumbnailData != nil
    }

    init(id: UUID = UUID(), position: Int = 0, imageData: Data?, thumbnailData: Data?) {
        self.id = id
        self.position = position
        self.imageData = imageData
        self.thumbnailData = thumbnailData
    }
}
