import Foundation
import SwiftData

final class SwiftDataRecipeRepository: RecipeRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [Recipe] {
        let descriptor = FetchDescriptor<RecipeModel>(sortBy: [SortDescriptor(\.title)])
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func create(_ recipe: Recipe) throws {
        modelContext.insert(recipe.toModel())
        try modelContext.save()
    }

    func update(_ recipe: Recipe) throws {
        let targetID = recipe.id
        let descriptor = FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == targetID })
        guard let model = try modelContext.fetch(descriptor).first else {
            throw RecipeRepositoryError.recipeNotFound
        }

        model.title = recipe.title
        model.steps = recipe.steps
        switch recipe.source {
        case .typed:
            model.isTypedSource = true
            model.sourceURL = nil
        case .url(let url):
            model.isTypedSource = false
            model.sourceURL = url
        }

        // The .cascade delete rule only fires on parent deletion, not on reassigning
        // the relationship array, so old children must be deleted explicitly here or
        // they leak as orphaned rows. Tags are left untouched: Phase 2.1 has no
        // tag-editing UI, and remapping recipe.tags would insert duplicate TagModel
        // rows for tags that already exist.
        model.ingredients.forEach { modelContext.delete($0) }
        model.ingredients = recipe.ingredients.map { $0.toModel() }

        try modelContext.save()
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
