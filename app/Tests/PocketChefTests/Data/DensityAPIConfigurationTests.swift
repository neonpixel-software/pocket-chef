@testable import PocketChef
import XCTest

final class DensityAPIConfigurationTests: XCTestCase {
    func testBuildsTheEntriesURLFromTheHost() {
        let configuration = DensityAPIConfiguration(host: "density.example.com", readKey: "key")

        XCTAssertEqual(configuration?.entriesURL.absoluteString, "https://density.example.com/density-entries")
        XCTAssertEqual(configuration?.readKey, "key")
    }

    /// Info.plist values from an xcconfig could carry stray spaces; they must not drop the API.
    func testIgnoresSurroundingWhitespace() {
        let configuration = DensityAPIConfiguration(host: " density.example.com ", readKey: " key ")

        XCTAssertEqual(configuration?.entriesURL.absoluteString, "https://density.example.com/density-entries")
        XCTAssertEqual(configuration?.readKey, "key")
    }

    func testAcceptsAHostWithAPort() {
        let configuration = DensityAPIConfiguration(host: "localhost:7032", readKey: "key")

        XCTAssertEqual(configuration?.entriesURL.absoluteString, "https://localhost:7032/density-entries")
    }

    func testRejectsAHostThatIsNotJustAHost() {
        XCTAssertNil(DensityAPIConfiguration(host: "density.example.com/api", readKey: "key"))
        XCTAssertNil(DensityAPIConfiguration(host: "user@density.example.com", readKey: "key"))
        XCTAssertNil(DensityAPIConfiguration(host: ":7032", readKey: "key"))
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
