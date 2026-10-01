import Foundation
import SwiftData

@MainActor
final class SwiftDataDensityCacheRepository: DensityCacheRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func apply(_ entries: [DensityEntry]) throws -> DensityCacheChanges {
        // The server's names are unique ignoring case, but two could still share a lookup key
        // (e.g. differing only in Unicode form). Keep the last one rather than fail the save.
        var incoming: [String: DensityEntry] = [:]
        for entry in entries {
            incoming[entry.id] = entry
        }

        var changes = DensityCacheChanges()
        for model in try modelContext.fetch(FetchDescriptor<DensityEntryModel>()) {
            guard let entry = incoming.removeValue(forKey: model.lookupKey) else {
                modelContext.delete(model)
                changes.removed += 1
                continue
            }
            if model.toDomain() != entry {
                model.ingredientName = entry.ingredientName
                model.gramsPerMilliliter = entry.gramsPerMilliliter
                model.lastModified = entry.lastModified
                changes.updated += 1
            }
        }
        for entry in incoming.values {
            modelContext.insert(entry.toModel())
            changes.added += 1
        }

        if !changes.isEmpty {
            try modelContext.save()
        }
        return changes
    }

    func entry(forIngredientNamed name: String) throws -> DensityEntry? {
        let key = DensityEntry.lookupKey(for: name)
        var descriptor = FetchDescriptor<DensityEntryModel>(predicate: #Predicate { $0.lookupKey == key })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func allEntries() throws -> [DensityEntry] {
        try modelContext.fetch(FetchDescriptor<DensityEntryModel>(sortBy: [SortDescriptor(\.lookupKey)])).map { $0.toDomain() }
    }

    func isEmpty() throws -> Bool {
        try modelContext.fetchCount(FetchDescriptor<DensityEntryModel>()) == 0
    }
}
