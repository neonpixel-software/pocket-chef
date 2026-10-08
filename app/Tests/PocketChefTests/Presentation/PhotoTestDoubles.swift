import Foundation
import ImageIO
@testable import PocketChef
import UniformTypeIdentifiers
import XCTest

/// Thumbnails by photo id; an unknown id has none, like a photo not downloaded yet.
struct StubFetchPhotoThumbnailUseCase: FetchPhotoThumbnailUseCase {
    var thumbnails: [UUID: Data] = [:]

    func execute(id: UUID) throws -> Data? {
        thumbnails[id]
    }
}

/// Thumbnails by photo id that counts its reads, for checking a cache.
final class CountingFetchPhotoThumbnailUseCase: FetchPhotoThumbnailUseCase {
    var thumbnails: [UUID: Data]
    private(set) var reads = 0

    init(thumbnails: [UUID: Data] = [:]) {
        self.thumbnails = thumbnails
    }

    func execute(id: UUID) throws -> Data? {
        reads += 1
        return thumbnails[id]
    }
}

/// Full images by photo id; an unknown id has none, like a photo not downloaded yet.
struct StubFetchPhotoImageUseCase: FetchPhotoImageUseCase {
    var images: [UUID: Data] = [:]

    func execute(id: UUID) throws -> Data? {
        images[id]
    }
}

/// Turns any data into a ProcessedPhoto derived from it, unless `fails` returns true for it.
struct FakePhotoProcessor: PhotoProcessor {
    var fails: @Sendable (Data) -> Bool = { _ in false }

    func process(_ data: Data) async throws -> ProcessedPhoto {
        if fails(data) { throw PhotoProcessingError.unreadableImage }
        return Self.processed(data)
    }

    static func processed(_ data: Data) -> ProcessedPhoto {
        ProcessedPhoto(imageData: Data("image:".utf8) + data, thumbnailData: Data("thumb:".utf8) + data)
    }
}

extension RecipeFormViewModel.Dependencies {
    /// The form's dependencies with stand-ins for the ones a test doesn't care about.
    static func testing(
        createRecipeUseCase: CreateRecipeUseCase,
        updateRecipeUseCase: UpdateRecipeUseCase,
        fetchTagsUseCase: FetchTagsUseCase,
        findOrCreateTagUseCase: FindOrCreateTagUseCase,
        fetchPhotoThumbnailUseCase: FetchPhotoThumbnailUseCase = StubFetchPhotoThumbnailUseCase(),
        photoProcessor: PhotoProcessor = FakePhotoProcessor()
    ) -> Self {
        Self(
            createRecipeUseCase: createRecipeUseCase,
            updateRecipeUseCase: updateRecipeUseCase,
            fetchTagsUseCase: fetchTagsUseCase,
            findOrCreateTagUseCase: findOrCreateTagUseCase,
            fetchPhotoThumbnailUseCase: fetchPhotoThumbnailUseCase,
            photoProcessor: photoProcessor
        )
    }
}

enum TestImages {
    /// A 4 × 4 red PNG that Image(photoData:) can decode.
    static func png() throws -> Data {
        let context = try XCTUnwrap(CGContext(
            data: nil, width: 4, height: 4, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        let image = try XCTUnwrap(context.makeImage())
        let data = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return data as Data
    }
}
