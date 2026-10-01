@testable import PocketChef
import XCTest

final class DensityAPIConfigurationTests: XCTestCase {
    func testBuildsTheEntriesURLFromTheHost() {
        let configuration = DensityAPIConfiguration(host: "density.example.com", readKey: "key")

        XCTAssertEqual(configuration?.entriesURL.absoluteString, "https://density.example.com/density-entries")
        XCTAssertEqual(configuration?.readKey, "key")
    }

    func testReadsTheInfoPlistKeys() {
        let configuration = DensityAPIConfiguration(infoDictionary: [
            "DensityAPIHost": "density.example.com",
            "DensityAPIReadKey": "key",
        ])

        XCTAssertEqual(configuration, DensityAPIConfiguration(host: "density.example.com", readKey: "key"))
    }

    /// Without DensityAPI.xcconfig, $(DENSITY_API_HOST) expands to an empty string.
    func testIsNilWhenTheXcconfigIsMissing() {
        XCTAssertNil(DensityAPIConfiguration(infoDictionary: ["DensityAPIHost": "", "DensityAPIReadKey": ""]))
        XCTAssertNil(DensityAPIConfiguration(infoDictionary: ["DensityAPIHost": "density.example.com", "DensityAPIReadKey": " "]))
        XCTAssertNil(DensityAPIConfiguration(infoDictionary: [:]))
        XCTAssertNil(DensityAPIConfiguration(infoDictionary: nil))
    }
}
