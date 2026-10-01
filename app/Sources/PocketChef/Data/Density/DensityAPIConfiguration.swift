import Foundation

/// Where the density API lives and the read key it wants. Both come from the gitignored
/// app/Config/DensityAPI.xcconfig through the Info.plist (see DensityAPI.xcconfig.example),
/// because the repo is public. Builds without it (CI, a fresh clone) have no configuration,
/// so the app never fetches and lookups find nothing.
struct DensityAPIConfiguration: Equatable {
    static let hostKey = "DensityAPIHost"
    static let readKeyKey = "DensityAPIReadKey"

    let entriesURL: URL
    let readKey: String

    init?(host: String, readKey: String) {
        let host = host.trimmingCharacters(in: .whitespaces)
        let readKey = readKey.trimmingCharacters(in: .whitespaces)
        guard !host.isEmpty, !readKey.isEmpty else { return nil }
        // Parsed as an authority, so a port works too (`localhost:7032`, the local API).
        guard var components = URLComponents(string: "https://\(host)"),
              let parsedHost = components.host, !parsedHost.isEmpty,
              components.path.isEmpty, components.user == nil else { return nil }
        components.path = "/density-entries"
        guard let url = components.url else { return nil }
        entriesURL = url
        self.readKey = readKey
    }

    init?(infoDictionary: [String: Any]?) {
        guard let host = infoDictionary?[Self.hostKey] as? String,
              let readKey = infoDictionary?[Self.readKeyKey] as? String else { return nil }
        self.init(host: host, readKey: readKey)
    }
}
