#if DEBUG
import Foundation
import SwiftData

extension ModelContext {
    /// Seeds a couple of sample recipes when the store is empty, so Phase 1.3's
    /// read-only list/detail views have something to show before Phase 2 adds real entry.
    func seedSampleDataIfNeeded() {
        let existingCount = (try? fetchCount(FetchDescriptor<RecipeModel>())) ?? 0
        guard existingCount == 0 else { return }

        for recipe in SampleData.recipes {
            insert(recipe.toModel())
        }
        try? save()
    }
}
#endif
