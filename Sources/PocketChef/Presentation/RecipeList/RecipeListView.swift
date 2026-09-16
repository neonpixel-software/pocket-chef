import SwiftUI

struct RecipeListView: View {
    @State private var viewModel: RecipeListViewModel
    @State private var isPresentingNewRecipe = false
    @State private var isPresentingAddChooser = false
    @State private var isPresentingCapture = false
    @State private var isPresentingCaptureUnavailableAlert = false
    /// Staged between the capture sheet dismissing and the review sheet presenting, so the
    /// two sheet transitions don't race (see the sheet's onDismiss below).
    @State private var pendingCaptureReview: Recipe?
    @State private var reviewingCapturedRecipe: Recipe?

    init(viewModel: RecipeListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !viewModel.allTags.isEmpty {
                    tagFilterRow
                }

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
                    } else if viewModel.filteredRecipes.isEmpty {
                        ContentUnavailableView(
                            "No Recipes With This Tag",
                            systemImage: "tag"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredRecipes) { recipe in
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
            }
            .background(PCColor.background)
            .safeAreaInset(edge: .top, spacing: 0) {
                PCHeader(title: "Recipes")
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingAddChooser = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .confirmationDialog("Add Recipe", isPresented: $isPresentingAddChooser, titleVisibility: .visible) {
                Button("Type It") {
                    if viewModel.isCaptureAvailable {
                        isPresentingCapture = true
                    } else {
                        isPresentingCaptureUnavailableAlert = true
                    }
                }
                Button("Enter Manually") { isPresentingNewRecipe = true }
                Button("Cancel", role: .cancel) {}
            }
            .alert("AI Capture Unavailable", isPresented: $isPresentingCaptureUnavailableAlert) {
                Button("OK") { isPresentingNewRecipe = true }
            } message: {
                Text("AI capture isn't available on this device. You can still enter the recipe by hand.")
            }
            .sheet(isPresented: $isPresentingNewRecipe) {
                RecipeFormView(viewModel: viewModel.makeNewRecipeFormViewModel()) { _ in
                    viewModel.load()
                    viewModel.loadTags()
                }
            }
            .sheet(isPresented: $isPresentingCapture, onDismiss: {
                if let recipe = pendingCaptureReview {
                    pendingCaptureReview = nil
                    reviewingCapturedRecipe = recipe
                }
            }) {
                RecipeCaptureView(viewModel: viewModel.makeCaptureViewModel()) { recipe in
                    pendingCaptureReview = recipe
                    isPresentingCapture = false
                }
            }
            .sheet(item: $reviewingCapturedRecipe) { recipe in
                RecipeFormView(viewModel: viewModel.makeCaptureReviewFormViewModel(for: recipe)) { _ in
                    viewModel.load()
                    viewModel.loadTags()
                }
            }
        }
        .tint(PCColor.pink)
        .task {
            viewModel.load()
            viewModel.loadTags()
        }
    }

    private var tagFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TagChip(title: "All", isSelected: viewModel.selectedTagID == nil) {
                    viewModel.selectTag(nil)
                }
                ForEach(viewModel.allTags) { tag in
                    TagChip(title: tag.name, isSelected: viewModel.selectedTagID == tag.id) {
                        viewModel.selectTag(tag.id)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(PCColor.background)
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

                if !recipe.tags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(recipe.tags) { tag in
                            Text(tag.name)
                                .font(PCFont.body(11, weight: .bold))
                                .foregroundStyle(PCColor.ink)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 3)
                                .background(PCColor.teal, in: Capsule())
                        }
                    }
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
        deleteRecipeUseCase: DefaultDeleteRecipeUseCase(repository: PreviewRecipeRepository()),
        fetchTagsUseCase: DefaultFetchTagsUseCase(repository: PreviewTagRepository()),
        findOrCreateTagUseCase: DefaultFindOrCreateTagUseCase(repository: PreviewTagRepository()),
        captureRecipeUseCase: DefaultCaptureRecipeUseCase(captureService: PreviewRecipeCaptureService()),
        checkCaptureAvailabilityUseCase: DefaultCheckCaptureAvailabilityUseCase(captureService: PreviewRecipeCaptureService())
    ))
}
