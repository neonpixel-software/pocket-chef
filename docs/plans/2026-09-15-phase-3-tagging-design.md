# Phase 3: Tagging — design

Source: `PLAN.md` Phase 3 (3.1 Tag model + assignment UI, 3.2 Filter recipe
list by tag).

Acceptance (from PLAN.md):
- 3.1: a recipe can carry multiple tags mixing presets and custom ones;
  tags persist.
- 3.2: selecting a tag narrows the list to matching recipes; clearing it
  restores the full list.

## Scope decisions

- **Preset tags**: Breakfast, Lunch, Dinner, Dessert, Snack — five common
  meal-type presets, seeded once at app launch (not DEBUG-gated, unlike
  the existing sample-recipe seeding, since presets must exist in release
  builds too).
- **Tag assignment UI**: an inline toggleable chip row directly in
  `RecipeFormView` (presets first, then existing custom tags), matching
  the app's existing card/chip aesthetic and the inline "Add X" pattern
  already used for ingredients/steps. Rejected a separate tag-picker sheet
  as an extra screen for no real benefit here.
- **Custom tag creation**: a "+ New Tag" chip swaps in place for a small
  inline text field; confirming creates (or reuses) the tag and adds it
  as a selected chip.
- **Duplicate tag names**: case-insensitive reuse. Typing "breakfast" when
  "Breakfast" already exists selects the existing tag rather than creating
  a near-duplicate that would silently split recipes across two
  effectively-identical filters.
- **List filter UI**: a horizontal scrolling chip row above the list
  ("All" + each tag, single-select), not a native `Picker(.segmented)` —
  segmented control gets cramped past ~4-5 tags and this app's tag count
  is unbounded (custom tags).
- **List row tag display**: now that a recipe can carry multiple tags,
  `RecipeRow` shows *all* assigned tags (wrapped), not just the first —
  showing only one would look like data went missing.

## Domain + Data layer

New `TagRepository` protocol — deliberately minimal, two methods:

```swift
protocol TagRepository {
    func fetchAll() throws -> [Tag]
    func findOrCreate(name: String) throws -> Tag
}
```

No bare `create`: `findOrCreate` is the *only* path a custom tag is ever
created through (the "+ New Tag" flow), so a separate create method would
be dead API surface. Presets are seeded independently, not through this
repository method.

`SwiftDataTagRepository.findOrCreate(name:)`: trims input, fetches all
`TagModel`s, matches case-insensitively in Swift (SwiftData predicates
don't portably support case-insensitive string compare), returns the
match or inserts+returns a new `TagModel(name:, isPreset: false)`.

**Preset seeding**: `ModelContext.seedPresetTagsIfNeeded()` (mirrors the
existing DEBUG-only `seedSampleDataIfNeeded()` shape, but called
unconditionally from `PocketChefApp.init()`): inserts each preset from
`Tag.presetNames` whose name (case-insensitive) doesn't already exist
among *any* tag, preset or custom — not gated on the `isPreset` flag. This
means a pre-existing custom tag named "Snack" blocks the preset "Snack"
from ever being seeded (keeping its `isPreset: false`) rather than the two
coexisting as near-duplicates; deliberate, not an oversight — see the
Addendum below for how this was arrived at. Idempotent — a second call is
a no-op once every preset name is present under some tag.

**Tag *assignment* persistence — the part that has to be careful**:
`SwiftDataRecipeRepository.update()` currently has a comment saying tags
are "intentionally untouched" (true for Phase 2.1, which had no tag UI).
That changes now, but naively doing `model.tags = recipe.tags.map {
$0.toModel() }` (the same pattern used for ingredients) would be wrong —
it constructs *new* `TagModel` instances sharing an `id` with
already-persisted rows, conflicting with `@Attribute(.unique)`. Instead,
both `create()` and `update()` **resolve** `recipe.tags` to the real
persisted `TagModel` rows by id (`FetchDescriptor` with an
`ids.contains($0.id)` predicate) and assign those to the relationship —
never fabricate tag rows at recipe-save time. Safe because every `Tag` a
form holds by save time came from `fetchAll()` or `findOrCreate()`, both
of which only ever return real persisted tags.

## Use cases

Two, matching the existing one-method-per-use-case pattern:
- `FetchTagsUseCase.execute() throws -> [Tag]`
- `FindOrCreateTagUseCase.execute(name: String) throws -> Tag`

No "assign tags to recipe" use case — assignment is just part of the
existing `Recipe.tags` field, saved through the existing
`CreateRecipeUseCase`/`UpdateRecipeUseCase`, same as ingredients/steps.

## Presentation layer

- **`RecipeFormViewModel`** gains `allTags: [Tag]`, `selectedTagIDs: Set<UUID>`,
  `newTagName: String`, `isAddingNewTag: Bool`, and `loadTags()`,
  `toggleTag(_:)`, `beginAddingNewTag()`, `confirmNewTag()` (trims, calls
  `findOrCreateTagUseCase`, adds to `allTags`/`selectedTagIDs` if not
  already present, resets the inline field). `buildRecipe()` now includes
  `allTags.filter { selectedTagIDs.contains($0.id) }` instead of the
  hardcoded `[]` (create) / untouched passthrough (edit). In `.edit` mode,
  `selectedTagIDs` is pre-seeded from `original.tags`. Two new
  dependencies (`fetchTagsUseCase`, `findOrCreateTagUseCase`) — four total,
  consistent with `RecipeListViewModel` already holding four.
- **`RecipeListViewModel`** gains `allTags: [Tag]`, `selectedTagID: UUID?`
  (nil = "All"), a `filteredRecipes` computed property, `selectTag(_:)`,
  and `loadTags()` alongside the existing `load()`. Needs
  `fetchTagsUseCase` too — five dependencies.
- **Shared `TagChip` view** (new, `Presentation/DesignSystem/`): a small
  selectable capsule button (selected/unselected via `PCColor`), reused by
  both the form's tag section and the list's filter row.
- **`RecipeFormView`**: new "Tags" section below Steps, using a small
  custom `FlowLayout: Layout` (wrapping, matching the approved two-line
  mockup) to lay out preset + custom `TagChip`s, plus the "+ New Tag" chip
  that swaps to an inline text field when tapped.
- **`RecipeListView`**: new horizontal `ScrollView` chip row (All + tags)
  above the list, wired to `selectedTagID`/`filteredRecipes`. `RecipeRow`
  switches from showing only `tags.first` to showing *all* assigned tags
  via the same `FlowLayout`.

## Testing plan

- **`TagRepository`** (SwiftData integration tests): `fetchAll` returns
  presets + custom; `findOrCreate` returns the existing tag
  case-insensitively rather than duplicating; `findOrCreate` creates a new
  tag when nothing matches. Preset seeding is idempotent (a second call
  doesn't duplicate presets).
- **Use cases**: `FetchTagsUseCaseTests`, `FindOrCreateTagUseCaseTests` —
  thin fake-repository tests mirroring the existing ones.
- **`SwiftDataRecipeRepository`**: extend create/update tests to prove tag
  relationships reference the *existing* `TagModel` rows rather than
  creating duplicates — two recipes both tagged "Breakfast" (via
  `findOrCreate` returning the same `Tag` both times) should leave exactly
  one `TagModel` row for it in the store.
- **`RecipeFormViewModel`**: toggle add/remove, new-tag confirm flow
  (including case-insensitive dedup), `buildRecipe()` includes selected
  tags, edit-mode pre-selects from `original.tags`.
- **`RecipeListViewModel`**: selecting a tag narrows `filteredRecipes`;
  selecting "All" (nil) restores the full list.
- **View tests** (ViewInspector, per the established pattern from Phase
  2.1 — see `reference-viewinspector` memory): tag chip rendering/toggling
  on both `RecipeFormView` and `RecipeListView`.

## Addendum: found during implementation

- **`RecipeDetailView` now displays assigned tags too** (a small chip row
  above Ingredients), not called out in the original design — an obvious
  gap once the form let you assign multiple tags and the list showed them
  all: viewing a recipe's full detail without seeing its tags would be an
  inconsistent experience.
- **Real bug in `seedPresetTagsIfNeeded()`, found via manual testing**: the
  first implementation bailed out entirely if *any* `isPreset == true` tag
  already existed (`guard presetCount == 0`). On the dev store carried over
  from Phase 2.1 manual testing, two ad-hoc "Breakfast"/"Dinner" tags from
  `SampleData` already satisfied that guard, so Lunch/Dessert/Snack never
  got seeded — confirmed live (filter row showed only 2 of 5 presets).
  Fixed to check each preset name individually and insert only the missing
  ones, matching "ensure presets exist" semantics rather than "seed once
  ever."
- **`buildRecipe()` hardened against a save-before-load race**: an existing
  Phase 2.1 test (`testSaveInEditModePreservesOriginalIdentitySourceAndTagsAndCallsUpdateUseCase`)
  failed once `tags: []`/`tags: original.tags` was replaced with the
  selected-tags computation, because it never called `loadTags()` first, so
  `allTags` was empty and `allTags.filter { selectedTagIDs.contains($0.id) }`
  dropped the pre-selected original tags entirely. Rather than just fixing
  the test, `buildRecipe()` now falls back to `initialTags` for any
  selected id not (yet) found in `allTags`, so a save that somehow races
  ahead of `loadTags()` still preserves the recipe's original tags instead
  of silently dropping them.

## Addendum: review round fixes (PR #14)

- `Recipe.toModel()` no longer maps `tags` at all (was constructing
  throwaway `TagModel` instances immediately overwritten by
  `resolveTagModels` in `create()`) — `RecipeModel`'s `tags` defaults to
  `[]`, and the repository always resolves tags explicitly.
- `Tag.presetNames` is now the single source of truth for the preset list,
  referenced by `seedPresetTagsIfNeeded()` instead of a second hardcoded
  array.
- `seedPresetTagsIfNeeded()`'s `save()` failure is now logged instead of
  silently swallowed via `try?` — presets are load-bearing enough (an
  empty filter row is a visible regression) to be worth surfacing even
  without a logging framework in place yet.
- Left as-is, per the review's own "not a blocker" framing: `findOrCreate`
  fetching all tags per call (fine at this tag-count scale), and the
  view models' pass-through-DI-container shape (same pattern already
  deferred in PR #12's review, now at 6-7 dependencies).
