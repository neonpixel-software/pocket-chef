import ImageIO
@testable import PocketChef
import UniformTypeIdentifiers
import XCTest

/// The fixtures are drawn here and encoded with ImageIO, so the tests need no image files.
final class ImageIOPhotoProcessorTests: XCTestCase {
    private let processor = ImageIOPhotoProcessor()

    // MARK: - Fixtures

    /// A width×height image, red on the left half and blue on the right.
    private func drawImage(width: Int, height: Int) throws -> CGImage {
        let context = try XCTUnwrap(CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB)),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        context.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width / 2, height: height))
        context.setFillColor(red: 0, green: 0, blue: 1, alpha: 1)
        context.fill(CGRect(x: width / 2, y: 0, width: width - width / 2, height: height))
        return try XCTUnwrap(context.makeImage())
    }

    private func encode(_ image: CGImage, as type: UTType, properties: [CFString: Any] = [:]) throws -> Data {
        let data = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return data as Data
    }

    /// A camera-style JPEG: location, camera and date metadata, stored sideways with
    /// EXIF orientation 6 (displayed rotated 90° clockwise).
    private func cameraJPEG(width: Int, height: Int) throws -> Data {
        try encode(drawImage(width: width, height: height), as: .jpeg, properties: [
            kCGImagePropertyOrientation: 6,
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude: 52.37,
                kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLongitude: 4.89,
                kCGImagePropertyGPSLongitudeRef: "E",
            ],
            kCGImagePropertyTIFFDictionary: [
                kCGImagePropertyTIFFMake: "Apple",
                kCGImagePropertyTIFFModel: "iPhone 12",
            ],
            kCGImagePropertyExifDictionary: [
                kCGImagePropertyExifDateTimeOriginal: "2026:10:07 18:30:00",
            ],
        ])
    }

    // MARK: - Reading the output

    private func image(_ data: Data) throws -> CGImage {
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        return try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
    }

    private func properties(_ data: Data) throws -> [CFString: Any] {
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        return try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
    }

    private func size(_ data: Data) throws -> CGSize {
        let image = try image(data)
        return CGSize(width: image.width, height: image.height)
    }

    /// The (red, blue) of the pixel at column, row, counted from the top-left.
    private func redAndBlue(in data: Data, column: Int, row: Int) throws -> (red: UInt8, blue: UInt8) {
        let image = try image(data)
        var pixel = [UInt8](repeating: 0, count: 4)
        let context = try XCTUnwrap(CGContext(
            data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB)),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        // Shift the image so the wanted pixel lands on the 1×1 context (origin bottom-left).
        context.draw(image, in: CGRect(x: -column, y: row - image.height + 1, width: image.width, height: image.height))
        return (pixel[0], pixel[2])
    }

    // MARK: - Tests

    func testScalesALargePhotoToTheMaximumSizeKeepingItsAspectRatio() async throws {
        let photo = try encode(drawImage(width: 4000, height: 3000), as: .jpeg)

        let processed = try await processor.process(photo)

        XCTAssertEqual(try size(processed.imageData), CGSize(width: 2048, height: 1536))
        XCTAssertEqual(try size(processed.thumbnailData), CGSize(width: 300, height: 225))
    }

    func testNeverScalesASmallImageUp() async throws {
        let photo = try encode(drawImage(width: 120, height: 80), as: .png)

        let processed = try await processor.process(photo)

        XCTAssertEqual(try size(processed.imageData), CGSize(width: 120, height: 80))
        XCTAssertEqual(try size(processed.thumbnailData), CGSize(width: 120, height: 80))
    }

    func testOutputsJPEG() async throws {
        let processed = try await processor.process(encode(drawImage(width: 400, height: 300), as: .png))

        for data in [processed.imageData, processed.thumbnailData] {
            let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
            XCTAssertEqual(CGImageSourceGetType(source) as String?, UTType.jpeg.identifier)
        }
    }

    func testAppliesTheEXIFOrientationToThePixels() async throws {
        let processed = try await processor.process(cameraJPEG(width: 400, height: 200))

        // Stored 400×200 and rotated 90° clockwise for display, so the left (red) half is on top.
        XCTAssertEqual(try size(processed.imageData), CGSize(width: 200, height: 400))
        let top = try redAndBlue(in: processed.imageData, column: 100, row: 50)
        let bottom = try redAndBlue(in: processed.imageData, column: 100, row: 350)
        XCTAssertGreaterThan(top.red, 200)
        XCTAssertLessThan(top.blue, 60)
        XCTAssertGreaterThan(bottom.blue, 200)
        XCTAssertLessThan(bottom.red, 60)
        let orientation = try properties(processed.imageData)[kCGImagePropertyOrientation] as? Int
        XCTAssertTrue(orientation == nil || orientation == 1, "orientation \(String(describing: orientation))")
    }

    func testStripsLocationCameraAndDateMetadata() async throws {
        let processed = try await processor.process(cameraJPEG(width: 400, height: 200))

        for data in [processed.imageData, processed.thumbnailData] {
            let properties = try properties(data)
            XCTAssertNil(properties[kCGImagePropertyGPSDictionary])
            let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
            XCTAssertNil(tiff?[kCGImagePropertyTIFFMake])
            XCTAssertNil(tiff?[kCGImagePropertyTIFFModel])
            let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
            XCTAssertNil(exif?[kCGImagePropertyExifDateTimeOriginal])
        }
    }

    func testReadsHEIC() async throws {
        let heic: Data
        do {
            heic = try encode(drawImage(width: 600, height: 400), as: .heic)
        } catch {
            throw XCTSkip("This platform can't encode HEIC fixtures")
        }

        let processed = try await processor.process(heic)

        XCTAssertEqual(try size(processed.imageData), CGSize(width: 600, height: 400))
    }

    func testRejectsDataThatIsNotAnImage() async {
        do {
            _ = try await processor.process(Data("not an image".utf8))
            XCTFail("expected PhotoProcessingError.unreadableImage")
        } catch {
            XCTAssertEqual(error as? PhotoProcessingError, .unreadableImage)
        }
    }

    func testRejectsEmptyData() async {
        do {
            _ = try await processor.process(Data())
            XCTFail("expected PhotoProcessingError.unreadableImage")
        } catch {
            XCTAssertEqual(error as? PhotoProcessingError, .unreadableImage)
        }
    }
}
