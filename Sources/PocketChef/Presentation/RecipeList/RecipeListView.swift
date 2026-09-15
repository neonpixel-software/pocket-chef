import SwiftUI

struct RecipeListView: View {
    @State private var viewModel: RecipeListViewModel
    @State private var isPresentingNewRecipe = false

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
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.recipes) { recipe in
                                NavigationLink(destination: RecipeDetailView(
                                    viewModel: viewModel.makeDetailViewModel(for: recipe),
                                    onRecipeChanged: { viewModel.load() }
                                )) {
                                    RecipeRow(recipe: recipe, onDelete: { viewModel.delete(recipe) })
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(PCColor.background)
            .safeAreaInset(edge: .top, spacing: 0) {
                PCHeader(title: "Recipes")
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingNewRecipe = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingNewRecipe) {
                RecipeFormView(viewModel: viewModel.makeNewRecipeFormViewModel()) { _ in
                    viewModel.load()
                }
            }
        }
        .tint(PCColor.pink)
        .task { viewModel.load() }
    }
}

private struct RecipeRow: View {
    let recipe: Recipe
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.title)
                    .font(PCFont.body(17, weight: .semibold))
                    .foregroundStyle(PCColor.textPrimary)

                if let tag = recipe.tags.first {
                    Text(tag.name)
                        .font(PCFont.body(11, weight: .bold))
                        .foregroundStyle(PCColor.ink)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(PCColor.teal, in: Capsule())
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(PCColor.textPrimary.opacity(0.35))
        }
        .padding(16)
        .background(PCColor.surface, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    PCFontRegistrar.registerCustomFonts()
    return RecipeListView(viewModel: RecipeListViewModel(
        fetchRecipesUseCase: DefaultFetchRecipesUseCase(repository: PreviewRecipeRepository()),
        createRecipeUseCase: DefaultCreateRecipeUseCase(repository: PreviewRecipeRepository()),
        updateRecipeUseCase: DefaultUpdateRecipeUseCase(repository: PreviewRecipeRepository()),
        deleteRecipeUseCase: DefaultDeleteRecipeUseCase(repository: PreviewRecipeRepository())
    ))
}
