import Foundation

/// Turns a picked or captured image into what's stored: scaled down, without metadata.
protocol PhotoProcessor: Sendable {
    func process(_ data: Data) async throws -> ProcessedPhoto
}

enum PhotoProcessingError: Error, Equatable {
    case unreadableImage
}
