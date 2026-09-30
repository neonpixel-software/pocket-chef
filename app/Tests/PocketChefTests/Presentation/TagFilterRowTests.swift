@testable import PocketChef
import ViewInspector
import XCTest

@MainActor
final class TagFilterRowTests: XCTestCase {
    private let breakfast = Tag(id: UUID(), name: "Breakfast", isPreset: true)
    private let dinner = Tag(id: UUID(), name: "Dinner", isPreset: true)

    /// Without a name, macOS VoiceOver announced a bare "scroll area" and skipped the chips (#78).
    func testRowIsNamedForAssistiveTech() throws {
        let sut = TagFilterRow(tags: [breakfast], selectedTagID: nil, onSelect: { _ in })

        let label = try sut.inspect().find(ViewType.ScrollView.self).accessibilityLabel().string()

        XCTAssertEqual(label, "Filter by Tag")
    }

    func testShowsAllChipFollowedByEachTag() throws {
        let sut = TagFilterRow(tags: [breakfast, dinner], selectedTagID: nil, onSelect: { _ in })

        let titles = try sut.inspect().findAll(TagChip.self).map { try $0.actualView().title }

        XCTAssertEqual(titles, ["All", "Breakfast", "Dinner"])
    }

    func testTappingTagChipSelectsThatTag() throws {
        nonisolated(unsafe) var selected: UUID?? = .none
        let sut = TagFilterRow(tags: [breakfast], selectedTagID: nil, onSelect: { selected = $0 })

        try sut.inspect().find(button: "Breakfast").tap()

        XCTAssertEqual(selected, .some(breakfast.id))
    }

    func testTappingAllClearsTheFilter() throws {
        nonisolated(unsafe) var selected: UUID?? = .none
        let sut = TagFilterRow(tags: [breakfast], selectedTagID: breakfast.id, onSelect: { selected = $0 })

        try sut.inspect().find(button: "All").tap()

        XCTAssertEqual(selected, .some(nil))
    }
}
