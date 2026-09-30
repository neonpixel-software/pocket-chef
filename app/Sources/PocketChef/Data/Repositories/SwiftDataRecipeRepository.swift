import Foundation
import SwiftData

final class SwiftDataRecipeRepository: RecipeRepository {
    /// Resolved on every call rather than stored, so a storage switch (PersistenceController)
    /// retargets the repository without rebuilding it.
    private let currentModelContext: () -> ModelContext
    private var modelContext: ModelContext {
        currentModelContext()
    }

    init(modelContext: @escaping @autoclosure () -> ModelContext) {
        currentModelContext = modelContext
    }

    func fetchAll() throws -> [Recipe] {
        let descriptor = FetchDescriptor<RecipeModel>(sortBy: [SortDescriptor(\.title)])
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func create(_ recipe: Recipe) throws {
        let model = recipe.toModel()
        model.tags = try resolveTagModels(for: recipe.tags)
        modelContext.insert(model)
        try modelContext.save()
    }

    func update(_ recipe: Recipe) throws {
        let targetID = recipe.id
        let descriptor = FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == targetID })
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RecipeRepositoryError.recipeNotFound
        }

        model.overwrite(with: recipe, in: modelContext)

        // Tags are a shared (non-owned) relationship: resolve to the existing,
        // already-persisted TagModel rows by id rather than remapping via
        // toModel(), which would insert duplicate rows for the same tag.
        model.tags = try resolveTagModels(for: recipe.tags)

        try modelContext.save()
    }

    private func resolveTagModels(for tags: [Tag]) throws -> [TagModel] {
        guard !tags.isEmpty else { return [] }
        let ids = Set(tags.map(\.id))
        let descriptor = FetchDescriptor<TagModel>(predicate: #Predicate { ids.contains($0.id) })
        return try modelContext.fetch(descriptor)
    }

    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == id })
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RecipeRepositoryError.recipeNotFound
        }
        modelContext.delete(model)
        try modelContext.save()
    }
}
