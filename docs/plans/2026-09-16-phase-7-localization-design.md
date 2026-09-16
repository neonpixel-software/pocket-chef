# Phase 7: Localization — design

Not originally in `PLAN.md`; inserted between the former Phase 6 (URL capture)
and Phase 7 (density API) at the user's request, ahead of the .NET backend
work. Existing Phase 7–10 renumbered to 8–11.

Languages: English (base), Spanish, French, German, Dutch.

## Important constraint

Spanish/French/German/Dutch translations are machine-translated in this
environment — there's no native speaker available to verify nuance or
naturalness. Everything about the *mechanism* (catalog wiring, correct
key→translation mapping, no missing entries, no layout breakage) is built,
tested, and manually verified here. Translation *quality* needs a fluent
reviewer before shipping, the same kind of gap as Phase 5/6's on-device AI
verification.

## Scope decisions

- **String Catalog (`Localizable.xcstrings`), not `.strings` files.** Current
  Apple standard, needs iOS 17+/macOS 14+ — this project targets 26, well
  past that. Gets native Xcode tooling and is the only mechanism SwiftUI's
  automatic `LocalizedStringKey` resolution targets.
- **Automatic resolution covers most of the app for free.** SwiftUI's
  `Text("...")`, `Button("...") { }`, `.navigationTitle("...")`,
  `TextField("...", text:)` etc. already take `LocalizedStringKey` when given
  a string *literal*, and SwiftUI resolves that against the catalog at
  runtime based on device language — no source changes needed for the ~50
  View-layer literals the survey found. This explicitly excludes strings that
  are the user's own content (recipe titles, ingredient text, steps, custom
  tag names) — those display exactly as entered, never localized.
- **Two exceptions need explicit `String(localized:)` code changes**, because
  they pass a runtime `String` (not a literal) into `Text`/a property, which
  bypasses automatic lookup:
  - **View-model error messages** (`RecipeCaptureViewModel`,
    `RecipeURLCaptureViewModel` — 3 messages total): wrapped with
    `String(localized:)` at the assignment site.
  - **Preset tag display names**: `Tag.name` stays the stored/matching key
    exactly as today (`"Breakfast"`, etc.) — untouched, so
    `FindOrCreateTagUseCase`'s case-insensitive matching and existing
    SwiftData rows keep working unchanged. A new `Tag.localizedDisplayName`
    computed property maps the canonical English key to a localized string
    only when `isPreset == true`; unknown/future preset names fall back to
    the stored key. User-created or user-renamed tags are never localized —
    `name` displays as typed, same as any other free-form user content.

## Testing plan

- **Automated, locale-pinned unit tests** for the two exception cases (8
  strings × 4 new locales = 32 assertions), using `String(localized:
  locale:)`'s explicit locale override — deterministic regardless of the
  test runner's system language:
  ```swift
  XCTAssertEqual(String(localized: "Breakfast", locale: Locale(identifier: "es")), "Desayuno")
  ```
  This catches missing/typo'd catalog entries with full automation, unlike
  the AI-dependent phases.
- **Not unit tested**: the ~50 View-layer strings resolved automatically by
  SwiftUI/Foundation — testing those would just be re-testing the platform's
  own localization mechanism, not app logic.
- **Manual verification**: run the built macOS app forcing Spanish (`-
  AppleLanguages "(es)"` launch argument), screenshot the recipe list,
  add-recipe chooser, capture screen, and recipe form — checking for no raw
  English fallback where a translation should apply, and no obviously broken
  layout (truncation, overlap). Repeat once for German as a second data
  point; French and Dutch use the identical code path and catalog format, so
  the mechanism is treated as proven once two locales confirm it end-to-end.

## Out of scope

- Translation quality review by a fluent speaker (flagged above, needs the
  user).
- Localizing `error.localizedDescription` fallbacks from repository-layer
  Swift errors (no `LocalizedError` conformances exist anywhere in the
  codebase today — those already fall back to Foundation's generic system
  message, unrelated to this phase's string catalog work).
- `SampleData.swift`'s DEBUG-only preview/seed recipe content — dev-only,
  never shown to real users.
