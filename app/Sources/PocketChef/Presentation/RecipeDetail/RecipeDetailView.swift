import SwiftUI

struct RecipeDetailView: View {
    /// Owned as @State: the list builds the view model inside its NavigationLink destination,
    /// which runs again whenever the list re-renders. With @Bindable the detail switched to
    /// that new view model and lost an open edit sheet or delete confirmation (#89).
    /// The trade-off: the detail keeps its first view model even after the list reloads, so it
    /// only stays current because no other screen can change a recipe while its detail is showing.
    /// If that changes (search, sync), refresh `viewModel.recipe` from the repository here.
    @State private var viewModel: RecipeDetailViewModel
    @Environment(\.dismiss) private var dismiss

    /// Invoked whenever this recipe is edited or deleted, so the list that pushed this
    /// screen can refresh — NavigationStack's `.onAppear` on pop-back isn't reliably
    /// re-triggered on macOS, so the list can't rely on lifecycle events alone.
    private let onRecipeChanged: () -> Void

    init(viewModel: RecipeDetailViewModel, onRecipeChanged: @escaping () -> Void = { /* no-op: not every caller needs to react to changes */ }) {
        _viewModel = State(initialValue: viewModel)
        self.onRecipeChanged = onRecipeChanged
    }

    private var recipe: Recipe { viewModel.recipe }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                if !recipe.tags.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(recipe.tags) { tag in
                            Text(tag.localizedDisplayName())
                                .font(PCFont.body(12, weight: .bold))
                                .foregroundStyle(PCColor.ink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(PCColor.teal, in: Capsule())
                        }
                    }
                }

                section(title: String(localized: "Ingredients"), accent: PCColor.teal) {
                    Group {
                        if recipe.ingredients.isEmpty {
                            Text("No ingredients listed")
                                .font(PCFont.body(15))
                                .foregroundStyle(PCColor.textPrimary.opacity(0.55))
                                .padding(16)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(recipe.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(PCColor.teal)
                                            .frame(width: 8, height: 8)
                                        Text(ingredient.rawText)
                                            .font(PCFont.body(15))
                                            .foregroundStyle(PCColor.textPrimary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)

                                    if index < recipe.ingredients.count - 1 {
                                        Divider().opacity(0.3)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .background(PCColor.surface, in: RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                }

                // Hidden when empty: most recipes, including every one saved before #82, have none.
                if !recipe.equipment.isEmpty {
                    section(title: String(localized: "Equipment"), accent: PCColor.deepTeal) {
                        VStack(spacing: 0) {
                            ForEach(Array(recipe.equipment.enumerated()), id: \.offset) { index, item in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(PCColor.deepTeal)
                                        .frame(width: 8, height: 8)
                                    Text(item)
                                        .font(PCFont.body(15))
                                        .foregroundStyle(PCColor.textPrimary)
                                    Spacer()
                                }
                                .padding(.vertical, 12)

                                if index < recipe.equipment.count - 1 {
                                    Divider().opacity(0.3)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .background(PCColor.surface, in: RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                    }
                }

                section(title: String(localized: "Steps"), accent: PCColor.pink) {
                    if recipe.steps.isEmpty {
                        Text("No steps listed")
                            .font(PCFont.body(15))
                            .foregroundStyle(PCColor.textPrimary.opacity(0.55))
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 14) {
                                    Text("\(index + 1)")
                                        .font(PCFont.body(13, weight: .bold))
                                        .foregroundStyle(PCColor.ink)
                                        .frame(width: 26, height: 26)
                                        .background(PCColor.pink, in: Circle())
                                    Text(step)
                                        .font(PCFont.body(15))
                                        .foregroundStyle(PCColor.textPrimary)
                                        .padding(.top, 3)
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(PCColor.background)
        .safeAreaInset(edge: .top, spacing: 0) {
            PCHeader(title: recipe.title)
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { viewModel.isPresentingEdit = true }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button("Delete", role: .destructive) { viewModel.isPresentingDeleteConfirmation = true }
            }
        }
        .sheet(isPresented: $viewModel.isPresentingEdit) {
            RecipeFormView(viewModel: viewModel.makeEditFormViewModel()) { saved in
                viewModel.recipe = saved
                onRecipeChanged()
            }
        }
        .confirmationDialog(
            "Delete this recipe?",
            isPresented: $viewModel.isPresentingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { viewModel.delete() }
            Button("Cancel", role: .cancel) { /* no-op: the dialog dismisses on its own */ }
        }
        .onChange(of: viewModel.isDeleted) { _, isDeleted in
            if isDeleted {
                onRecipeChanged()
                dismiss()
            }
        }
        .tint(PCColor.pink)
    }

    private func section(
        title: String,
        accent: Color,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(accent)
                    .frame(width: 11, height: 11)
                Text(title.uppercased())
                    .font(PCFont.body(13, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(PCColor.textPrimary)
            }
            content()
        }
    }
}

#Preview {
    PCFontRegistrar.registerCustomFonts()
    return NavigationStack {
        RecipeDetailView(viewModel: RecipeDetailViewModel(
            recipe: SampleData.recipes[0],
            createRecipeUseCase: DefaultCreateRecipeUseCase(repository: PreviewRecipeRepository()),
            updateRecipeUseCase: DefaultUpdateRecipeUseCase(repository: PreviewRecipeRepository()),
            deleteRecipeUseCase: DefaultDeleteRecipeUseCase(repository: PreviewRecipeRepository()),
            fetchTagsUseCase: DefaultFetchTagsUseCase(repository: PreviewTagRepository()),
            findOrCreateTagUseCase: DefaultFindOrCreateTagUseCase(repository: PreviewTagRepository())
        ))
    }
}
