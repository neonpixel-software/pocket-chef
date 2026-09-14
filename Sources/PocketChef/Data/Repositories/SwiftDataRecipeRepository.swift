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
}
