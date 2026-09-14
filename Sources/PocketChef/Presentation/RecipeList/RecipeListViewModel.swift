import Foundation
import Observation

@Observable
final class RecipeListViewModel {
    private(set) var recipes: [Recipe] = []
    private(set) var errorMessage: String?

    private let fetchRecipesUseCase: FetchRecipesUseCase

    init(fetchRecipesUseCase: FetchRecipesUseCase) {
        self.fetchRecipesUseCase = fetchRecipesUseCase
    }

    func load() {
        do {
            recipes = try fetchRecipesUseCase.execute()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
