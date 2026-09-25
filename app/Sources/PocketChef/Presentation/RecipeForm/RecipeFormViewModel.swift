import Foundation
import Observation

enum RecipeFormMode {
    case create
    case edit(Recipe)
    /// A freshly AI-captured recipe awaiting review before its first save — pre-fills like
    /// .edit, but save() creates a new record with a fresh id rather than updating.
    case capture(Recipe)
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

    /// Avoids "2.0" round-tripping into the field for a whole-number amount typed as "2".
    private static func formatAmount(_ amount: Double) -> String {
        amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(amount))
            : String(amount)
    }
}

struct EquipmentDraft: Identifiable, Equatable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String = "") {
        self.id = id
        self.name = name
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
    var equipment: [EquipmentDraft]
    var steps: [StepDraft]
    private(set) var allTags: [Tag] = []
    var selectedTagIDs: Set<UUID>
    var newTagName: String = ""
    var isAddingNewTag: Bool = false
    private(set) var errorMessage: String?

    private let mode: RecipeFormMode
    private let createRecipeUseCase: CreateRecipeUseCase
    private let updateRecipeUseCase: UpdateRecipeUseCase
    private let fetchTagsUseCase: FetchTagsUseCase
    private let findOrCreateTagUseCase: FindOrCreateTagUseCase
    /// The recipe's own tags at load time (edit mode only) — merged into allTags
    /// defensively in loadTags(), in case a fetch races ahead of a just-created tag.
    private let initialTags: [Tag]

    init(
        mode: RecipeFormMode,
        createRecipeUseCase: CreateRecipeUseCase,
        updateRecipeUseCase: UpdateRecipeUseCase,
        fetchTagsUseCase: FetchTagsUseCase,
        findOrCreateTagUseCase: FindOrCreateTagUseCase
    ) {
        self.mode = mode
        self.createRecipeUseCase = createRecipeUseCase
        self.updateRecipeUseCase = updateRecipeUseCase
        self.fetchTagsUseCase = fetchTagsUseCase
        self.findOrCreateTagUseCase = findOrCreateTagUseCase

        switch mode {
        case .create:
            title = ""
            ingredients = []
            equipment = []
            steps = []
            initialTags = []
        case let .edit(recipe), let .capture(recipe):
            title = recipe.title
            ingredients = recipe.ingredients.map { IngredientLineDraft(ingredientLine: $0) }
            equipment = recipe.equipment.map { EquipmentDraft(name: $0) }
            steps = recipe.steps.map { StepDraft(text: $0) }
            initialTags = recipe.tags
        }
        selectedTagIDs = Set(initialTags.map(\.id))
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

    func addEquipment() {
        equipment.append(EquipmentDraft())
    }

    func removeEquipment(at index: Int) {
        guard equipment.indices.contains(index) else { return }
        equipment.remove(at: index)
    }

    func moveEquipmentUp(at index: Int) {
        guard equipment.indices.contains(index), index > 0 else { return }
        equipment.swapAt(index, index - 1)
    }

    func moveEquipmentDown(at index: Int) {
        guard equipment.indices.contains(index), index < equipment.count - 1 else { return }
        equipment.swapAt(index, index + 1)
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

    func loadTags() {
        do {
            var tags = try fetchTagsUseCase.execute()
            for tag in initialTags where !tags.contains(where: { $0.id == tag.id }) {
                tags.append(tag)
            }
            allTags = tags.sortedPresetsFirst()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleTag(_ tag: Tag) {
        if selectedTagIDs.contains(tag.id) {
            selectedTagIDs.remove(tag.id)
        } else {
            selectedTagIDs.insert(tag.id)
        }
    }

    func beginAddingNewTag() {
        isAddingNewTag = true
    }

    func confirmNewTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        newTagName = ""
        isAddingNewTag = false
        guard !trimmed.isEmpty else { return }

        do {
            let tag = try findOrCreateTagUseCase.execute(name: trimmed)
            if !allTags.contains(where: { $0.id == tag.id }) {
                allTags.append(tag)
            }
            selectedTagIDs.insert(tag.id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func save() -> Recipe? {
        guard canSave else { return nil }

        let recipe = buildRecipe()

        do {
            switch mode {
            case .create, .capture:
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
        let builtEquipment = equipment
            .map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let builtSteps = steps
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        // Falls back to initialTags for any id not (yet) in allTags, so a save that
        // somehow races ahead of loadTags() still preserves the recipe's original
        // tags rather than silently dropping them. Filters a combined ordered list
        // (rather than mapping over selectedTagIDs directly) since Set iteration
        // order is undefined and tags is an ordered array.
        let tagSource = allTags + initialTags.filter { initial in !allTags.contains { $0.id == initial.id } }
        let selectedTags = tagSource.filter { selectedTagIDs.contains($0.id) }

        // Only the id and source differ per mode. .edit preserves both from the
        // original; .capture is a fresh record built from the captured draft, so it
        // gets a new id but keeps the draft's source.
        let (id, source) = switch mode {
        case .create: (UUID(), RecipeSource.typed)
        case let .capture(original): (UUID(), original.source)
        case let .edit(original): (original.id, original.source)
        }
        return Recipe(
            id: id,
            title: trimmedTitle,
            ingredients: builtIngredients,
            equipment: builtEquipment,
            steps: builtSteps,
            source: source,
            tags: selectedTags
        )
    }
}
