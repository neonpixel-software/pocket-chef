# Phase 5: AI-powered capture — typed text — design

Source: `PLAN.md` Phase 5 (5.1 "Type it" entry point, 5.2 No-Apple-Intelligence
fallback).

Acceptance (from PLAN.md):
- 5.1: typing a real recipe produces a correctly structured, editable
  result; saving stores it like any manual recipe.
- 5.2: on a simulator/device without Apple Intelligence, the "Type it" flow
  opens the blank form instead of erroring.

## Important constraint

This design was built without the ability to run or test Apple
Intelligence / FoundationModels — no device/simulator in this development
environment has it enabled, and there's no way to invoke a real on-device
model here. PLAN.md's own testing strategy anticipates this: the capture
service is "tested via a fake conforming to the same protocol for
use-case tests... real device checks with sample recipes handled as
manual/semi-automated verification, not strict pass-fail units." Every
layer except `FoundationModelsRecipeCaptureService` itself is built and
verified (unit tests, UI, manual app testing); that one piece needs
on-device verification before Phase 5.1's acceptance criterion is fully
satisfied.

The `@Generable`/`@Guide`/`LanguageModelSession` API shape used below was
confirmed against current Apple documentation and multiple independent
tutorials (framework requires iOS/macOS 26, matches this project's
deployment target). One specific risk was identified: `Optional<String>`
in a `@Generable` struct has a confirmed working example; `Optional<Double>`
does not, and couldn't be verified either way. Scope decision below hedges
against this.

## Scope decisions

- **Capture output schema hedges against the Optional<Double> risk**: all
  `@Generable` fields are `String`, including `amount` (empty string when
  not stated). Parsed to `Double?` in the same `toDomain()` mapping style
  already used by `RecipeFormViewModel.buildRecipe()` — reuses a pattern
  already proven to compile and run, rather than an unconfirmed one.
- **No separate `CapturedRecipe` domain type**: `Recipe` is already the
  right shape (title, ingredients, steps, source, tags) — the capture
  service returns `Recipe` directly (fresh id, `source: .typed`,
  `tags: []`).
- **`RecipeFormMode` gains `.capture(Recipe)`**, not a separate review
  screen: pre-fills identically to `.edit`, but `save()` creates a new
  record with a fresh id rather than updating. Chosen because PLAN.md
  Phase 6 (URL capture) needs the exact same "land on the review screen
  pre-filled" shape — `Recipe.source` already has both `.typed` and
  `.url(URL)` cases, so this generalizes for Phase 6 without further
  `RecipeFormViewModel` changes.
- **Entry point**: the list's `+` button becomes a chooser ("Type it" /
  "Enter Manually") instead of jumping straight to the blank form — a
  natural precursor to Phase 6.2's fuller "both options shown side by
  side" screen, which just adds "Paste a link" later.
- **Fallback UX**: tapping "Type it" when unavailable shows a one-line
  explanatory alert ("AI capture isn't available on this device"), then
  opens the blank manual form on dismissal — the capture screen itself is
  never shown. Chosen over a silent skip so the user isn't left wondering
  why nothing got auto-filled.
- **Capture failure UX**: stays on the capture screen with an inline error
  message rather than dumping the user into a confusing blank form — they
  can edit their pasted text and retry.

## Domain layer

```swift
protocol RecipeCaptureService {
    func isAvailable() -> Bool
    func captureRecipe(from text: String) async throws -> Recipe
}

enum RecipeCaptureError: Error {
    case captureFailed
}
```

Two new use cases, matching the established one-method pattern:
- `CaptureRecipeUseCase.execute(text: String) async throws -> Recipe`
- `CheckCaptureAvailabilityUseCase.execute() -> Bool`

Kept availability as its own use case (not a raw service call from a
view model) so `RecipeListViewModel`/`RecipeCaptureViewModel` stay
decoupled from any concrete service and stay fakeable in tests.

## Data layer — `FoundationModelsRecipeCaptureService`

The only place `import FoundationModels` appears, keeping that
dependency isolated to the Data layer:

```swift
import FoundationModels

final class FoundationModelsRecipeCaptureService: RecipeCaptureService {
    func isAvailable() -> Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    func captureRecipe(from text: String) async throws -> Recipe {
        let session = LanguageModelSession(instructions: {
            "Extract this recipe into a structured title, ingredient lines, and steps. Preserve the ingredient's exact original wording in rawText even when you also identify amount/unit/name."
        })
        do {
            let result = try await session.respond(to: text, generating: CapturedRecipeSchema.self)
            return result.content.toDomain()
        } catch {
            throw RecipeCaptureError.captureFailed
        }
    }
}
```

`isAvailable()` uses `if case .available = ...` rather than
`== .available` since direct `==` against `SystemLanguageModel.Availability`
(which has an associated-value `.unavailable(reason)` case) wasn't
confirmed to work — the pattern-match form is safe regardless.

```swift
@Generable
struct CapturedRecipeSchema {
    @Guide(description: "A short, descriptive title for the recipe")
    let title: String
    @Guide(description: "Each ingredient as a separate structured line")
    let ingredients: [CapturedIngredientSchema]
    @Guide(description: "Each preparation step in order, one instruction per entry")
    let steps: [String]
}

@Generable
struct CapturedIngredientSchema {
    @Guide(description: "The ingredient exactly as written in the source text, e.g. '2 cups flour'")
    let rawText: String
    @Guide(description: "Numeric quantity as a plain number string (e.g. \"2\", \"1.5\") if stated, else empty")
    let amount: String
    @Guide(description: "Unit of measurement (e.g. \"cup\", \"tsp\", \"g\") if stated, else empty")
    let unit: String
    @Guide(description: "The ingredient's name alone, without quantity/unit, if identifiable, else empty")
    let ingredientName: String
}
```

`toDomain()` mapping extensions reuse the exact empty-string→nil /
`Double(trimmed)` parsing already in `RecipeFormViewModel.buildRecipe()`.

## Presentation layer

- **`RecipeCaptureViewModel`** (new): `rawText: String`, `isCapturing: Bool`,
  `errorMessage: String?`, `canCapture` (blank-check, mirrors `canSave`).
  `capture()` calls `captureRecipeUseCase.execute(text:)`; returns the
  `Recipe` on success (caller builds the review screen), sets
  `errorMessage` and stays on the capture screen on failure.
- **`RecipeCaptureView`** (new): `TextEditor` for pasting/typing, a
  "Capture" action (disabled while blank/capturing, progress indicator
  while capturing), inline error on failure. On success, pushes
  `RecipeFormView(viewModel: RecipeFormViewModel(mode: .capture(recipe), ...))`.
- **`RecipeListView`**'s `+` button becomes a `.confirmationDialog`
  ("Add Recipe" / "Type it" / "Enter Manually" / "Cancel"), matching the
  delete-confirmation styling already used elsewhere in this view.
- **Fallback**: tapping "Type it" checks `viewModel.isCaptureAvailable`.
  If unavailable, an `.alert` explains and its dismissal opens the blank
  manual form directly — the capture screen is never shown in that case.
- **`RecipeListViewModel`** gains `isCaptureAvailable` (via
  `CheckCaptureAvailabilityUseCase`) and `makeCaptureViewModel() ->
  RecipeCaptureViewModel`. Dependency count grows to ~8 — continuing the
  already-flagged, already-deferred "pass-through DI container" pattern
  from the PR #12/#14 reviews.

## Testing plan

- `CaptureRecipeUseCaseTests`, `CheckCaptureAvailabilityUseCaseTests` —
  fake-service tests mirroring the existing pattern.
- `CapturedRecipeSchema`/`CapturedIngredientSchema` → domain mapping:
  unit-tested directly with synthetic instances (pure Swift, no
  FoundationModels runtime needed) — validates amount-parsing/
  nil-collapsing independent of any real AI call.
- `RecipeCaptureViewModelTests`: success returns the recipe; failure sets
  `errorMessage` without clearing `rawText`; `canCapture` blank-check.
- `RecipeFormViewModelTests`: new `.capture(recipe)` cases — prefills like
  `.edit`, but `save()` routes to `createRecipeUseCase` with a fresh id.
- View tests (ViewInspector) for `RecipeCaptureView` and the chooser
  dialog wiring.
- **Not unit tested**: `FoundationModelsRecipeCaptureService` itself —
  needs the user's on-device verification before Phase 5.1's acceptance
  criterion is fully satisfied.
