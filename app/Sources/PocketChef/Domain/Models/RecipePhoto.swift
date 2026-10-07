import Foundation

/// A photo in a recipe's gallery. It carries no image bytes: those load on demand through
/// RecipePhotoRepository, so mapping every recipe for the list never loads a photo.
/// The gallery order is the order of `Recipe.photos`; the first photo is the cover.
struct RecipePhoto: Identifiable, Equatable {
    let id: UUID
}

/// A photo ready to store: the scaled-down image and its thumbnail, both JPEG.
struct ProcessedPhoto: Equatable {
    let imageData: Data
    let thumbnailData: Data
}
