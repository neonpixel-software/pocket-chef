import Foundation
import SwiftData

final class SwiftDataDensityCacheRepository: DensityCacheRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func replaceAll(with entries: [DensityEntry]) throws {
        try modelContext.delete(model: DensityEntryModel.self)
        // The server's names are unique ignoring case, but two could still share a lookup key
        // (e.g. differing only in Unicode form). Keep the last one rather than fail the save.
        var byKey: [String: DensityEntry] = [:]
        for entry in entries {
            byKey[entry.id] = entry
        }
        for entry in byKey.values {
            modelContext.insert(entry.toModel())
        }
        try modelContext.save()
    }

    func entry(forIngredientNamed name: String) throws -> DensityEntry? {
        let key = DensityEntry.lookupKey(for: name)
        var descriptor = FetchDescriptor<DensityEntryModel>(predicate: #Predicate { $0.lookupKey == key })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func isEmpty() throws -> Bool {
        try modelContext.fetchCount(FetchDescriptor<DensityEntryModel>()) == 0
    }
}
