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
