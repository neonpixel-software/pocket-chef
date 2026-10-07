import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Scales a photo down and re-encodes it as JPEG with ImageIO, which reads the same formats
/// (HEIC, JPEG, PNG, …) on iOS and macOS. Only the pixels are written, so no location, camera
/// or date metadata is stored: the app collects no user data.
struct ImageIOPhotoProcessor: PhotoProcessor {
    static let maxImagePixelSize = 2048
    static let maxThumbnailPixelSize = 300
    static let compressionQuality = 0.8

    /// Nonisolated and async, so callers on the main actor don't decode on it.
    func process(_ data: Data) async throws -> ProcessedPhoto {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0,
              let longEdge = Self.longEdge(of: source) else {
            throw PhotoProcessingError.unreadableImage
        }

        let image = try Self.image(from: source, maxPixelSize: min(longEdge, Self.maxImagePixelSize))
        let thumbnail = try Self.image(from: source, maxPixelSize: min(longEdge, Self.maxThumbnailPixelSize))
        return try ProcessedPhoto(imageData: Self.jpeg(image), thumbnailData: Self.jpeg(thumbnail))
    }

    private static func longEdge(of source: CGImageSource) -> Int? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0 else {
            return nil
        }
        return max(width, height)
    }

    /// Decodes at most `maxPixelSize` on the long edge (never larger than the source, which
    /// the caller ensures) and applies the EXIF orientation to the pixels.
    private static func image(from source: CGImageSource, maxPixelSize: Int) throws -> CGImage {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw PhotoProcessingError.unreadableImage
        }
        return image
    }

    private static func jpeg(_ image: CGImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw PhotoProcessingError.unreadableImage
        }
        let options: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: compressionQuality]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw PhotoProcessingError.unreadableImage
        }
        return data as Data
    }
}
