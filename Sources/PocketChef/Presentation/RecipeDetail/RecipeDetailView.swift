import SwiftUI

struct RecipeDetailView: View {
    @State private var viewModel: RecipeDetailViewModel
    @State private var isPresentingEdit = false
    @State private var isPresentingDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    /// Invoked whenever this recipe is edited or deleted, so the list that pushed this
    /// screen can refresh — NavigationStack's `.onAppear` on pop-back isn't reliably
    /// re-triggered on macOS, so the list can't rely on lifecycle events alone.
    private let onRecipeChanged: () -> Void

    /// Test-only hook (ViewInspector's documented pattern for inspecting views with local
    /// @State, e.g. isPresentingEdit/isPresentingDeleteConfirmation below, which unlike the
    /// viewModel's own properties have no externally-held reference a test can read/mutate
    /// directly). Never set outside of tests.
    internal var didAppear: ((Self) -> Void)?

    init(viewModel: RecipeDetailViewModel, onRecipeChanged: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: viewModel)
        self.onRecipeChanged = onRecipeChanged
    }

    private var recipe: Recipe { viewModel.recipe }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                section(title: "Ingredients", accent: PCColor.teal) {
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

                section(title: "Steps", accent: PCColor.pink) {
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
                Button("Edit") { isPresentingEdit = true }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button("Delete", role: .destructive) { isPresentingDeleteConfirmation = true }
            }
        }
        .sheet(isPresented: $isPresentingEdit) {
            RecipeFormView(viewModel: viewModel.makeEditFormViewModel()) { saved in
                viewModel.recipe = saved
                onRecipeChanged()
            }
        }
        .confirmationDialog(
            "Delete this recipe?",
            isPresented: $isPresentingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { viewModel.delete() }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: viewModel.isDeleted) { _, isDeleted in
            if isDeleted {
                onRecipeChanged()
                dismiss()
            }
        }
        .tint(PCColor.pink)
        .onAppear { self.didAppear?(self) }
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        accent: Color,
        @ViewBuilder content: () -> Content
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
            deleteRecipeUseCase: DefaultDeleteRecipeUseCase(repository: PreviewRecipeRepository())
        ))
    }
}
