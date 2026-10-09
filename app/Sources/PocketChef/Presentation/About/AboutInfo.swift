import Foundation

/// What the About page shows that isn't prose (14.2): the links and the version. Plain data, so
/// the tests can check it without a view.
struct AboutInfo: Equatable {
    /// The links live here, not in the strings catalog: they aren't translated, and a typo in
    /// one language mustn't break a link.
    static let repositoryURL = URL(string: "https://github.com/neonpixel-software/pocket-chef")!
    static let newIssueURL = URL(string: "https://github.com/neonpixel-software/pocket-chef/issues/new")!

    let version: String
    let build: String

    init(version: String, build: String) {
        self.version = version
        self.build = build
    }

    /// The running app's version and build, from its Info.plist.
    init(bundle: Bundle = .main) {
        self.init(
            version: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?",
            build: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        )
    }

    /// "Version 0.1.0 (1)".
    var versionText: String {
        String(localized: "Version \(version) (\(build))")
    }
}
