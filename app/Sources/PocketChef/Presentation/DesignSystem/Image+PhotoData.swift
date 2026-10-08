import ImageIO
import SwiftUI

extension Image {
    /// An image from stored photo bytes (JPEG), or nil when they can't be decoded.
    init?(photoData: Data) {
        #if canImport(UIKit)
        guard let image = UIImage(data: photoData) else { return nil }
        self.init(uiImage: image)
        #else
        guard let image = NSImage(data: photoData) else { return nil }
        self.init(nsImage: image)
        #endif
    }
}

enum PhotoDecoder {
    /// Decodes stored photo bytes (JPEG) into pixels off the main actor, so a full-size
    /// gallery photo doesn't hitch scrolling or paging. Nil when they can't be decoded. The
    /// stored bytes carry no orientation: the photo processor already applied it.
    static func decode(_ data: Data) async -> CGImage? {
        await Task.detached(priority: .userInitiated) {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
            let options = [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
            return CGImageSourceCreateImageAtIndex(source, 0, options)
        }.value
    }
}
