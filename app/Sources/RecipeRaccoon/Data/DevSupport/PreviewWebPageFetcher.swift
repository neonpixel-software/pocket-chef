#if DEBUG
import Foundation

/// Lets SwiftUI previews render URL-capture UI without touching the network.
struct PreviewWebPageFetcher: WebPageFetcher {
    func fetchPlainText(from _: URL) async throws -> String {
        "Sample Recipe\n\n2 eggs\n1 cup flour\n\nMix well. Bake at 350F for 20 minutes."
    }
}
#endif
