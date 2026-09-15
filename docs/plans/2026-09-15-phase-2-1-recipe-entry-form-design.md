# Phase 2.1: Structured entry/edit form — design

Source: `PLAN.md` Phase 2.1. This screen is both the manual create/edit/delete
UI now, and the pre-filled review screen every later AI capture path (typed
text, URL) lands on in Phase 5/6.

Acceptance (from PLAN.md): a recipe can be created, edited, and deleted
entirely by hand; changes persist via SwiftData.

## Scope decisions

- **Ingredient input**: structured fields (Amount / Unit / Ingredient name)
  per line, with `rawText` composed from them automatically. Chosen over a
  single free-text field so manually-entered recipes can also participate in
  Phase 10 unit conversion, not just AI-captured ones.
- **Steps**: a reorderable list (add/remove/move), not just append-only.
- **Tags**: out of scope. Recipe.tags stays empty for created recipes and
  untouched for edited ones — Phase 3.1 owns tag assignment UI.
- **Row styling**: custom `PCColor`/`PCFont` cards (matching the app's
  existing visual identity from Phase 1.4), not native SwiftUI `List`/`Form`
  chrome. Reorder/delete via explicit up/down/× buttons rather than system
  swipe/drag gestures, for visual consistency with `RecipeListView` /
  `RecipeDetailView`.
- **Navigation**: `+` toolbar button on `RecipeListView` → sheet with a blank
  form. `RecipeDetailView` gets "Edit" (sheet, pre-filled) and "Delete"
  (confirmation dialog) toolbar actions. List rows get a context-menu delete
  (native `.swipeActions` requires `List`, and this app's rows are custom
  cards in a `ScrollView`, not `List`). The list refreshes via an explicit
  `onRecipeChanged` callback passed down into `RecipeDetailView`, invoked on
  successful edit/delete — confirmed by manual testing that `.onAppear`
  alone is *not* reliably re-triggered when popping back from a pushed
  `NavigationStack` destination on macOS, so relying on it left the list
  showing stale data after an edit or delete.

## Domain layer

`RecipeRepository` gains:

```swift
protocol RecipeRepository {
    func fetchAll() throws -> [Recipe]
    func create(_ recipe: Recipe) throws
    func update(_ recipe: Recipe) throws
    func delete(id: UUID) throws
}

enum RecipeRepositoryError: Error, Equatable {
    case recipeNotFound
}
```

Three new use cases, matching the existing `FetchRecipesUseCase` pattern
(protocol + `Default*` implementation, no shared base class):
`CreateRecipeUseCase`, `UpdateRecipeUseCase`, `DeleteRecipeUseCase`. Each
`Default*` just forwards to the repository — no validation here; that's a
presentation-layer (form) concern.

## Data layer — `SwiftDataRecipeRepository`

```swift
func create(_ recipe: Recipe) throws {
    modelContext.insert(recipe.toModel())
    try modelContext.save()
}

func update(_ recipe: Recipe) throws {
    let targetID = recipe.id
    let descriptor = FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == targetID })
    guard let model = try modelContext.fetch(descriptor).first else {
        throw RecipeRepositoryError.recipeNotFound
    }

    model.title = recipe.title
    model.steps = recipe.steps
    switch recipe.source {
    case .typed:
        model.isTypedSource = true
        model.sourceURL = nil
    case .url(let url):
        model.isTypedSource = false
        model.sourceURL = url
    }

    model.ingredients.forEach { modelContext.delete($0) }
    model.ingredients = recipe.ingredients.map { $0.toModel() }
    // tags intentionally untouched — see "Tags" scope decision above.

    try modelContext.save()
}

func delete(id: UUID) throws {
    let descriptor = FetchDescriptor<RecipeModel>(predicate: #Predicate { $0.id == id })
    guard let model = try modelContext.fetch(descriptor).first else {
        throw RecipeRepositoryError.recipeNotFound
    }
    modelContext.delete(model)
    try modelContext.save()
}
```

`create` reuses `Recipe.toModel()` directly (safe: a newly-created `Recipe`
always has `tags: []`). `update` fetches and mutates the live persisted
model in place rather than reusing `toModel()` wholesale — it explicitly
deletes old `IngredientLineModel` children before replacing them, since the
`.cascade` delete rule only fires on *parent* deletion, not on reassigning
the relationship array (skipping this would leak orphaned ingredient rows).

`PreviewRecipeRepository` gets the three new methods as no-ops returning
canned data, so previews keep compiling.

## Presentation — `RecipeFormViewModel`

```swift
enum RecipeFormMode {
    case create
    case edit(Recipe)
}

struct IngredientLineDraft: Identifiable {
    let id: UUID
    var amount: String = ""
    var unit: String = ""
    var ingredientName: String = ""
}

@Observable
final class RecipeFormViewModel {
    var title: String = ""
    var ingredients: [IngredientLineDraft] = []
    var steps: [String] = []
    private(set) var errorMessage: String?
    private(set) var isSaving = false

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func addIngredient() { ... }
    func removeIngredient(at offsets: IndexSet) { ... }
    func moveIngredient(from: IndexSet, to: Int) { ... }
    func addStep() { ... }
    func removeStep(at offsets: IndexSet) { ... }
    func moveStep(from: IndexSet, to: Int) { ... }

    func save() -> Recipe? { ... }
}
```

`save()`:
- No-ops (returns `nil`) if `!canSave`.
- Builds `[IngredientLine]`: if *all three* structured fields are blank, the
  row is dropped **unless** it was hydrated from an existing line that had
  a non-empty `rawText` with no structured data (e.g. a raw AI-captured
  ingredient, or hand-seeded sample data) — that original `rawText` is
  preserved as-is instead of being silently deleted. (Found via manual
  testing: editing "Pancakes" from `SampleData`, which has a raw-only
  `"1 egg"` line, and saving without touching that row used to drop the
  egg entirely, since the structured-only UI has no field to represent a
  line with no parseable amount/unit/name.) Otherwise composes `rawText`
  by joining the non-empty trimmed parts with spaces (e.g.
  `"2 cups flour"`), parses `amount` via `Double(trimmed)` (nil if
  unparseable — no error, it just won't structure for unit conversion
  later).
- Filters `steps` to non-blank, trimmed entries.
- `.create`: fresh `UUID()`, `source: .typed`, `tags: []`, calls
  `createRecipeUseCase.execute(recipe)`.
- `.edit(let original)`: keeps `original.id`/`source`/`tags`, calls
  `updateRecipeUseCase.execute(recipe)`.
- Catches thrown errors into `errorMessage`, returns `nil` on failure;
  returns the saved `Recipe` on success so the caller can update local state
  without a full reload.
- `init(mode:)` pre-fills fields from `original` when mode is `.edit`.

## Presentation — views & navigation

- **`RecipeFormView`**: `title` `TextField`; "Ingredients" section (a custom
  card per `IngredientLineDraft` with Amount/Unit/Name fields + up/down/×
  controls, plus "Add Ingredient"); "Steps" section (card per step with a
  multi-line field + up/down/×, plus "Add Step"). Toolbar: Cancel / Save
  (disabled when `!canSave`). Takes `onSave: (Recipe) -> Void`.
- **`RecipeListView`**: `+` toolbar button → `.sheet` with
  `RecipeFormView(mode: .create)`; `onSave` dismisses. Rows get
  `.swipeActions` destructive delete → `viewModel.delete(recipe)` (calls
  `DeleteRecipeUseCase`, removes locally). `.task { load() }` →
  `.onAppear { load() }`.
- **`RecipeDetailView`** gets a new `RecipeDetailViewModel` (settable
  `recipe`, `deleteRecipeUseCase`, `errorMessage`). Toolbar: "Edit" (sheet →
  `RecipeFormView(mode: .edit(recipe))`, `onSave` updates `viewModel.recipe`
  and dismisses) and "Delete" (confirmation dialog → `viewModel.delete()` →
  dismiss/pop on success; list's `.onAppear` picks up the removal).
- **`PocketChefApp`** wires the three new use cases at the composition root.

## Testing plan

- **Use cases**: `CreateRecipeUseCaseTests`, `UpdateRecipeUseCaseTests`,
  `DeleteRecipeUseCaseTests` — fake-repository tests mirroring
  `FetchRecipesUseCaseTests` (success passthrough + error propagation).
- **Data layer**: extend `SwiftDataRecipeRepositoryTests` with create/update/
  delete cases against the in-memory store, including: update replaces
  ingredients without orphaning old rows, update/delete on a nonexistent id
  throws `.recipeNotFound`.
- **View models**: `RecipeFormViewModelTests` (fakes for both use cases) —
  `canSave` toggling, add/remove/move for both ingredients and steps,
  `rawText` composition, blank-row filtering, create-vs-update routing,
  error handling. `RecipeListViewModelTests` gains delete cases. New
  `RecipeDetailViewModelTests` for delete success/failure.
- Views aren't unit tested (consistent with current project state) — manual
  verification on macOS + iOS simulator before calling this done.
