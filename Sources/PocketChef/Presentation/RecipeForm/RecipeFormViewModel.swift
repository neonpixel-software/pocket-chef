import Foundation
import Observation

enum RecipeFormMode {
    case create
    case edit(Recipe)
}

struct IngredientLineDraft: Identifiable, Equatable {
    let id: UUID
    var amount: String
    var unit: String
    var ingredientName: String
    /// The original rawText this row was hydrated from, if any (e.g. an AI-captured
    /// line with no structured fields). Preserved so that saving an edit without
    /// touching this row doesn't silently drop an ingredient the structured fields
    /// alone can't represent — see buildRecipe().
    fileprivate let originalRawText: String

    init(id: UUID = UUID(), amount: String = "", unit: String = "", ingredientName: String = "") {
        self.id = id
        self.amount = amount
        self.unit = unit
        self.ingredientName = ingredientName
        originalRawText = ""
    }

    init(ingredientLine: IngredientLine) {
        id = ingredientLine.id
        amount = ingredientLine.amount.map(Self.formatAmount) ?? ""
        unit = ingredientLine.unit ?? ""
        ingredientName = ingredientLine.ingredientName ?? ""
        originalRawText = ingredientLine.rawText
    }

    // Avoids "2.0" round-tripping into the field for a whole-number amount typed as "2".
    private static func formatAmount(_ amount: Double) -> String {
        amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(amount))
            : String(amount)
    }
}

struct StepDraft: Identifiable, Equatable {
    let id: UUID
    var text: String

    init(id: UUID = UUID(), text: String = "") {
        self.id = id
        self.text = text
    }
}

@Observable
final class RecipeFormViewModel {
    var title: String
    var ingredients: [IngredientLineDraft]
    var steps: [StepDraft]
    private(set) var errorMessage: String?

    private let mode: RecipeFormMode
    private let createRecipeUseCase: CreateRecipeUseCase
    private let updateRecipeUseCase: UpdateRecipeUseCase

    init(
        mode: RecipeFormMode,
        createRecipeUseCase: CreateRecipeUseCase,
        updateRecipeUseCase: UpdateRecipeUseCase
    ) {
        self.mode = mode
        self.createRecipeUseCase = createRecipeUseCase
        self.updateRecipeUseCase = updateRecipeUseCase

        switch mode {
        case .create:
            title = ""
            ingredients = []
            steps = []
        case .edit(let recipe):
            title = recipe.title
            ingredients = recipe.ingredients.map { IngredientLineDraft(ingredientLine: $0) }
            steps = recipe.steps.map { StepDraft(text: $0) }
        }
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func addIngredient() {
        ingredients.append(IngredientLineDraft())
    }

    func removeIngredient(at index: Int) {
        guard ingredients.indices.contains(index) else { return }
        ingredients.remove(at: index)
    }

    func moveIngredientUp(at index: Int) {
        guard ingredients.indices.contains(index), index > 0 else { return }
        ingredients.swapAt(index, index - 1)
    }

    func moveIngredientDown(at index: Int) {
        guard ingredients.indices.contains(index), index < ingredients.count - 1 else { return }
        ingredients.swapAt(index, index + 1)
    }

    func addStep() {
        steps.append(StepDraft())
    }

    func removeStep(at index: Int) {
        guard steps.indices.contains(index) else { return }
        steps.remove(at: index)
    }

    func moveStepUp(at index: Int) {
        guard steps.indices.contains(index), index > 0 else { return }
        steps.swapAt(index, index - 1)
    }

    func moveStepDown(at index: Int) {
        guard steps.indices.contains(index), index < steps.count - 1 else { return }
        steps.swapAt(index, index + 1)
    }

    @discardableResult
    func save() -> Recipe? {
        guard canSave else { return nil }

        let recipe = buildRecipe()

        do {
            switch mode {
            case .create:
                try createRecipeUseCase.execute(recipe)
            case .edit:
                try updateRecipeUseCase.execute(recipe)
            }
            errorMessage = nil
            return recipe
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func buildRecipe() -> Recipe {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let builtIngredients = ingredients.compactMap { draft -> IngredientLine? in
            let amount = draft.amount.trimmingCharacters(in: .whitespacesAndNewlines)
            let unit = draft.unit.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = draft.ingredientName.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !amount.isEmpty || !unit.isEmpty || !name.isEmpty else {
                // No structured fields were ever filled in for this row. If it was
                // hydrated from an existing line with no structured data (e.g. a raw
                // AI-captured ingredient), keep it as-is rather than silently dropping
                // it just because the structured-only form can't represent it.
                guard !draft.originalRawText.isEmpty else { return nil }
                return IngredientLine(id: draft.id, rawText: draft.originalRawText)
            }

            let rawText = [amount, unit, name].filter { !$0.isEmpty }.joined(separator: " ")
            return IngredientLine(
                id: draft.id,
                rawText: rawText,
                amount: Double(amount),
                unit: unit.isEmpty ? nil : unit,
                ingredientName: name.isEmpty ? nil : name
            )
        }
        let builtSteps = steps
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        switch mode {
        case .create:
            return Recipe(
                id: UUID(),
                title: trimmedTitle,
                ingredients: builtIngredients,
                steps: builtSteps,
                source: .typed,
                tags: []
            )
        case .edit(let original):
            return Recipe(
                id: original.id,
                title: trimmedTitle,
                ingredients: builtIngredients,
                steps: builtSteps,
                source: original.source,
                tags: original.tags
            )
        }
    }
}
