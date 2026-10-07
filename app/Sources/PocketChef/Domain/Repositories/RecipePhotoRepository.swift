import Foundation

/// Loads photo bytes on demand. Photos are added, removed and reordered by saving their
/// recipe (RecipeRepository), not here.
protocol RecipePhotoRepository {
    /// The thumbnail, or nil when the photo is unknown or its bytes aren't on this device yet
    /// (CloudKit hasn't downloaded them).
    func thumbnail(id: UUID) throws -> Data?
    /// The full image, or nil under the same conditions as `thumbnail(id:)`.
    func image(id: UUID) throws -> Data?
}
