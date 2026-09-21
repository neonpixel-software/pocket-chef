import SwiftUI

struct RecipeFormView: View {
    @Bindable private var viewModel: RecipeFormViewModel
    @Environment(\.dismiss) private var dismiss
    let onSave: (Recipe) -> Void

    init(viewModel: RecipeFormViewModel, onSave: @escaping (Recipe) -> Void) {
        _viewModel = Bindable(viewModel)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    titleField

                    formSection(title: String(localized: "Ingredients"), accent: PCColor.teal) {
                        VStack(spacing: 12) {
                            ForEach(Array(viewModel.ingredients.enumerated()), id: \.element.id) { index, _ in
                                IngredientRow(
                                    draft: $viewModel.ingredients[index],
                                    canMoveUp: index > 0,
                                    canMoveDown: index < viewModel.ingredients.count - 1,
                                    onMoveUp: { viewModel.moveIngredientUp(at: index) },
                                    onMoveDown: { viewModel.moveIngredientDown(at: index) },
                                    onDelete: { viewModel.removeIngredient(at: index) }
                                )
                            }
                            addButton(title: String(localized: "Add Ingredient")) { viewModel.addIngredient() }
                        }
                    }

                    formSection(title: String(localized: "Steps"), accent: PCColor.pink) {
                        VStack(spacing: 12) {
                            ForEach(Array(viewModel.steps.enumerated()), id: \.element.id) { index, _ in
                                StepRow(
                                    stepNumber: index + 1,
                                    text: $viewModel.steps[index].text,
                                    canMoveUp: index > 0,
                                    canMoveDown: index < viewModel.steps.count - 1,
                                    onMoveUp: { viewModel.moveStepUp(at: index) },
                                    onMoveDown: { viewModel.moveStepDown(at: index) },
                                    onDelete: { viewModel.removeStep(at: index) }
                                )
                            }
                            addButton(title: String(localized: "Add Step")) { viewModel.addStep() }
                        }
                    }

                    formSection(title: String(localized: "Tags"), accent: PCColor.deepTeal) {
                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.allTags) { tag in
                                TagChip(
                                    title: tag.localizedDisplayName(),
                                    isSelected: viewModel.selectedTagIDs.contains(tag.id),
                                    action: { viewModel.toggleTag(tag) }
                                )
                            }

                            if viewModel.isAddingNewTag {
                                TextField("Tag name", text: $viewModel.newTagName)
                                    .font(PCFont.body(13, weight: .semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(PCColor.surface, in: Capsule())
                                    .frame(width: 120)
                                    .onSubmit { viewModel.confirmNewTag() }
                            } else {
                                TagChip(title: String(localized: "+ New Tag"), isSelected: false) {
                                    viewModel.beginAddingNewTag()
                                }
                            }
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(PCFont.body(13))
                            .foregroundStyle(PCColor.pink)
                    }
                }
                .padding(20)
            }
            .background(PCColor.background)
            .navigationTitle("Recipe")
            .task { viewModel.loadTags() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let saved = viewModel.save() {
                            onSave(saved)
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
        .tint(PCColor.pink)
    }

    private var titleField: some View {
        TextField("Recipe title", text: $viewModel.title)
            .font(PCFont.body(20, weight: .semibold))
            .foregroundStyle(PCColor.textPrimary)
            .padding(16)
            .background(PCColor.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    private func formSection(
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

    private func addButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: "plus.circle.fill")
                .font(PCFont.body(15, weight: .semibold))
                .foregroundStyle(PCColor.deepTeal)
        }
    }
}

private struct IngredientRow: View {
    @Binding var draft: IngredientLineDraft
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    TextField("Amount", text: $draft.amount)
                        .frame(width: 64)
                    TextField("Unit", text: $draft.unit)
                        .frame(width: 72)
                    TextField("Ingredient name", text: $draft.ingredientName)
                }
                .font(PCFont.body(15))
                .foregroundStyle(PCColor.textPrimary)
                .textFieldStyle(.plain)
            }
            .padding(12)
            .background(PCColor.surface, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)

            RowControls(canMoveUp: canMoveUp, canMoveDown: canMoveDown, onMoveUp: onMoveUp, onMoveDown: onMoveDown, onDelete: onDelete)
        }
    }
}

private struct StepRow: View {
    let stepNumber: Int
    @Binding var text: String
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(stepNumber)")
                    .font(PCFont.body(13, weight: .bold))
                    .foregroundStyle(PCColor.ink)
                    .frame(width: 26, height: 26)
                    .background(PCColor.pink, in: Circle())
                TextField("Step description", text: $text, axis: .vertical)
                    .font(PCFont.body(15))
                    .foregroundStyle(PCColor.textPrimary)
                    .textFieldStyle(.plain)
                    .lineLimit(1...6)
            }
            .padding(12)
            .background(PCColor.surface, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)

            RowControls(canMoveUp: canMoveUp, canMoveDown: canMoveDown, onMoveUp: onMoveUp, onMoveDown: onMoveDown, onDelete: onDelete)
        }
    }
}

private struct RowControls: View {
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: onMoveUp) {
                Image(systemName: "chevron.up")
            }
            .disabled(!canMoveUp)
            .accessibilityLabel(String(localized: "Move up"))
            Button(action: onMoveDown) {
                Image(systemName: "chevron.down")
            }
            .disabled(!canMoveDown)
            .accessibilityLabel(String(localized: "Move down"))
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(PCColor.pink)
            }
            .accessibilityLabel(String(localized: "Delete"))
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(PCColor.textPrimary.opacity(0.55))
        .buttonStyle(.plain)
        .padding(.top, 12)
    }
}

#Preview {
    PCFontRegistrar.registerCustomFonts()
    return RecipeFormView(
        viewModel: RecipeFormViewModel(
            mode: .create,
            createRecipeUseCase: DefaultCreateRecipeUseCase(repository: PreviewRecipeRepository()),
            updateRecipeUseCase: DefaultUpdateRecipeUseCase(repository: PreviewRecipeRepository()),
            fetchTagsUseCase: DefaultFetchTagsUseCase(repository: PreviewTagRepository()),
            findOrCreateTagUseCase: DefaultFindOrCreateTagUseCase(repository: PreviewTagRepository())
        ),
        onSave: { _ in }
    )
}
