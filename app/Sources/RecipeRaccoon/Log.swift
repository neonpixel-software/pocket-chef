import Foundation
import os

/// Loggers for the app's error paths, one per layer, so failures reach the unified log
/// (Console, sysdiagnose) in TestFlight and App Store builds. `print()` output only shows under
/// the Xcode debugger: on a normal launch it's discarded (#214). The logs stay on the device.
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.neonpixel.reciperaccoon"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let data = Logger(subsystem: subsystem, category: "data")
    static let domain = Logger(subsystem: subsystem, category: "domain")
    static let presentation = Logger(subsystem: subsystem, category: "presentation")
}

extension Error {
    /// The error's type, domain and code ("StorageModeError RecipeRaccoon.StorageModeError 1"),
    /// which never hold user content, so they can be logged `.public` and read in a user's
    /// sysdiagnose. The description can quote a URL or recipe text and stays private.
    var logSummary: String {
        let nsError = self as NSError
        return "\(type(of: self)) \(nsError.domain) \(nsError.code)"
    }
}
