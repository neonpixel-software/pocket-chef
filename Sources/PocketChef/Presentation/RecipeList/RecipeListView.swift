import SwiftUI

struct RecipeListView: View {
    @State private var viewModel: RecipeListViewModel

    init(viewModel: RecipeListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Couldn't Load Recipes",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else if viewModel.recipes.isEmpty {
                    ContentUnavailableView(
                        "No Recipes Yet",
                        systemImage: "fork.knife"
                    )
                } else {
                    List(viewModel.recipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            Text(recipe.title)
                        }
                    }
                }
            }
            .navigationTitle("Recipes")
        }
        .task { viewModel.load() }
    }
}

#Preview {
    RecipeListView(viewModel: RecipeListViewModel(
        fetchRecipesUseCase: DefaultFetchRecipesUseCase(repository: PreviewRecipeRepository())
    ))
}

private struct PreviewRecipeRepository: RecipeRepository {
    func fetchAll() throws -> [Recipe] {
        SampleData.recipes
    }
}
