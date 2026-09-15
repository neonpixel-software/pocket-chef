import Foundation
import SwiftData

final class SwiftDataTagRepository: TagRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [Tag] {
        let descriptor = FetchDescriptor<TagModel>(sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func findOrCreate(name: String) throws -> Tag {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // Case-insensitive match to avoid near-duplicate tags (e.g. "breakfast" vs
        // "Breakfast") that would silently split recipes across two effectively
        // identical filters. SwiftData predicates don't portably support
        // case-insensitive string comparison, so this matches in Swift.
        let existing = try modelContext.fetch(FetchDescriptor<TagModel>())
        if let match = existing.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return match.toDomain()
        }

        let model = TagModel(name: trimmed, isPreset: false)
        modelContext.insert(model)
        try modelContext.save()
        return model.toDomain()
    }
}
