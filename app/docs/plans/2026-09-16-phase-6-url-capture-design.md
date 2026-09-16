# Phase 6: AI-powered capture — URL — design

Source: `PLAN.md` Phase 6 (6.1 "Paste a link" entry point, 6.2 add-recipe
screen shows both options clearly).

Acceptance (from PLAN.md):
- 6.1: pasting a real recipe URL produces a correctly structured, editable
  result with ads/backstory/comments excluded.
- 6.2: both entry points ("Type it" / "Paste a link") are visible without
  extra taps from the main add-recipe screen.

## Important constraint

Same constraint as Phase 5: this design was built without the ability to
fetch a real page and run it through Apple Intelligence in this
environment (no device/simulator here has Apple Intelligence enabled,
and network access to arbitrary URLs isn't exercised in CI either).
Everything around the AI call — URL validation, page fetching, HTML→text
conversion, use-case chaining, view model, view — is built and unit
tested. The AI extraction step itself reuses the exact same
`FoundationModelsRecipeCaptureService`/`CapturedRecipeSchema` pipeline
already shipped and left pending on-device verification in Phase 5.1, so
Phase 6.1's acceptance criterion is pending the same on-device check.

## Scope decisions

- **No new AI-facing contract.** `RecipeCaptureService.captureRecipe(from:
  String)` and `CaptureRecipeUseCase` are reused unchanged — URL capture
  fetches a page, converts it to plain text, then feeds that text through
  the exact same pipeline typed capture already uses. This was the whole
  point of `Recipe.source` already having a `.url(URL)` case and
  `RecipeFormMode.capture(Recipe)` being source-agnostic (noted explicitly
  in the Phase 5 design doc as being built for this).
- **HTML → plain text before handing to the model**, not raw HTML. Cuts
  token noise from scripts/styles/nav markup and keeps the prompt focused
  on visible content. Done via `NSAttributedString(data:options:
  [.documentType: .html], documentAttributes:).string` — built into
  Foundation, no new dependency.
- **Fetching and HTML conversion are split into two pieces**: a pure
  `HTMLPlainTextConverter.plainText(fromHTML:) -> String?` (fully unit
  testable, no network) and a `URLSessionWebPageFetcher` that does the
  network round-trip and delegates conversion to it. The network call
  itself isn't exercised by real requests in tests, matching how
  `FoundationModelsRecipeCaptureService` is handled — excluded from
  coverage with a documented reason, not test-padded.
- **Distinct failure messages.** A `WebPageFetchError` (bad URL, fetch
  failed, empty page) and a `RecipeCaptureError` (AI couldn't extract a
  recipe) are different failure modes with different user actions, so the
  URL capture view model surfaces two different messages instead of one
  generic one.
- **Entry point stays the `+` chooser**, gains a third option: "Paste a
  Link" between "Type It" and "Enter Manually". Satisfies 6.2 — the
  chooser is the add-recipe screen's entry surface, and all three options
  appear together the moment it opens; no additional taps needed to see
  them. "Paste a Link" is gated by the same `isCaptureAvailable` check and
  "AI unavailable" alert as "Type It", since it depends on Apple
  Intelligence too.

## Domain layer

```swift
protocol WebPageFetcher: Sendable {
    func fetchPlainText(from url: URL) async throws -> String
}

enum WebPageFetchError: Error {
    case invalidURL
    case requestFailed(underlying: Error)
    case emptyContent
}

protocol CaptureRecipeFromURLUseCase: Sendable {
    func execute(urlString: String) async throws -> Recipe
}
```

`DefaultCaptureRecipeFromURLUseCase` validates the URL string
(`URL(string:)` succeeds and the scheme starts with "http"; otherwise
throws `.invalidURL`), calls `webPageFetcher.fetchPlainText(from:)`, then
delegates to the existing `captureRecipeUseCase.execute(text:)`. Errors
from each stage propagate with their own type, which is what lets the
view model tell fetch failures apart from AI-extraction failures.

## Data layer

```swift
enum HTMLPlainTextConverter {
    static func plainText(fromHTML html: String) -> String? {
        guard let data = html.data(using: .utf8) else { return nil }
        guard let attributed = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil
        ) else { return nil }
        let text = attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }
}

final class URLSessionWebPageFetcher: WebPageFetcher {
    func fetchPlainText(from url: URL) async throws -> String {
        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(from: url)
        } catch {
            throw WebPageFetchError.requestFailed(underlying: error)
        }
        guard let html = String(data: data, encoding: .utf8),
              let plainText = HTMLPlainTextConverter.plainText(fromHTML: html) else {
            throw WebPageFetchError.emptyContent
        }
        return plainText
    }
}
```

`HTMLPlainTextConverter` lives in `Data/Capture/` alongside
`CapturedRecipeSchema.swift` and is unit tested directly (pure function,
no network, no FoundationModels). `URLSessionWebPageFetcher` is excluded
from coverage the same way `FoundationModelsRecipeCaptureService` is —
documented in `sonar-project.properties` — since a real network round
trip isn't something to exercise in CI.

## Presentation layer

- **`RecipeURLCaptureViewModel`** (new): `urlText: String`, `isCapturing:
  Bool`, `errorMessage: String?`, `canCapture` (non-blank after trimming).
  `capture()` calls `captureRecipeFromURLUseCase.execute(urlString:)`; on
  catch, checks whether the error is a `WebPageFetchError` (message:
  "Couldn't load that page. Check the link and try again.") or anything
  else (message: "Couldn't find a recipe on that page. Check it over and
  try again."), logging the underlying error either way for on-device
  debugging — same pattern as the Phase 5 PR #17 review fix.
- **`RecipeURLCaptureView`** (new): single-line URL text field (not a
  `TextEditor`), title "Paste a Link", same Cancel/Capture toolbar shape
  as `RecipeCaptureView`. On success, stages the recipe the same way
  `RecipeListView` already does for typed capture.
- **`RecipeListView`**'s chooser dialog gains "Paste a Link" between
  "Type It" and "Enter Manually", reusing the same `isCaptureAvailable`
  check and unavailable-alert as "Type It" (both need Apple Intelligence).
  A second staging var (`pendingURLCaptureReview`) and a second
  `.sheet(isPresented:)` for the URL capture screen follow the identical
  pattern as the typed-capture sheet — the multiple-`.sheet` fragility
  flagged in PR #17's review is unchanged/not addressed here, still
  tracked as separate follow-up debt.
- **`RecipeListViewModel`** gains `captureRecipeFromURLUseCase` and
  `makeURLCaptureViewModel() -> RecipeURLCaptureViewModel`, following the
  same construction pattern as `makeCaptureViewModel()`.

## Testing plan

- `HTMLPlainTextConverterTests`: strips tags/scripts/styles, collapses to
  `nil` on empty/whitespace-only result.
- `CaptureRecipeFromURLUseCaseTests`: invalid URL throws `.invalidURL`
  without calling the fetcher; fetcher failure propagates
  `WebPageFetchError`; successful fetch delegates to a fake
  `CaptureRecipeUseCase` and returns its `Recipe`.
- `RecipeURLCaptureViewModelTests`: `canCapture` blank-check; success path
  returns the recipe; `WebPageFetchError` vs. AI-error failure paths set
  the two distinct messages.
- `RecipeURLCaptureViewTests` (ViewInspector): Capture button
  disabled/enabled by `canCapture`, Cancel exists, error message renders.
- `RecipeListViewModelTests`: new fakes/use case wiring for
  `makeURLCaptureViewModel()`.
- **Not unit tested**: `URLSessionWebPageFetcher`'s real network call —
  excluded from coverage, same treatment as
  `FoundationModelsRecipeCaptureService`. The AI-extraction step is
  already excluded there and isn't retested here.
