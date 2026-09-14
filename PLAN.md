# Pocket Chef — Plan

A NeonPixel app for macOS, iPadOS, and iOS. Lets you gather recipes with zero friction: type one in or paste a URL, and it's stored clean, no ads, no life story, just the recipe. Tag recipes (breakfast, dinner, custom tags, multiple per recipe) and switch ingredient measurements between volume (cups, spoons) and weight (grams). The app gathers no data of the user and no ads will be shown. The app is completely anonymous.

This is the source of truth for architecture and the phase-by-phase implementation plan. The name-brainstorm/decision history lives in the vault note this was moved from.

## Architecture

One SwiftUI codebase targets all three platforms (macOS, iPadOS, iOS). Local data uses SwiftData; when a user opts into iCloud (a settings toggle, not a default), the same SwiftData store syncs via CloudKit, no separate code path.

Recipe capture (typed text and URL extraction) runs entirely on-device via Apple Intelligence — no server round-trip, keeps it fast and private. Devices without Apple Intelligence support fall back straight to a blank structured entry form.

A separate, purpose-built .NET API (hosted on an existing Ubuntu 26.04 VPS) does exactly one job: serve ingredient density data (grams per cup) for unit conversion. It is not involved in recipe storage, sync, or capture — fully decoupled from the client app.

## Architecture & coding guidelines

Priority for this project: maintainable, testable, scalable over fastest-to-ship. Clean Architecture on both the client and the API, targeting **90%+ test coverage** on both projects.

**Swift app (Clean Architecture + MVVM, not MV):** MV was considered but rejected — it binds views straight to SwiftData's query system, which couples UI to persistence and undermines the whole point of Clean Architecture. Layers:
- **Domain** — plain Swift structs (`Recipe`, `IngredientLine`, `Tag`, `DensityEntry`) and protocols (repositories, capture service). No SwiftData or networking imports; fully unit-testable in isolation.
- **Data** — concrete implementations: SwiftData-backed repositories, the Apple Intelligence capture service, the density API client. SwiftData `@Model` classes are kept fully separate from domain structs, with explicit mapping code between them (more boilerplate, chosen deliberately for full decoupling over the lighter-weight option of models doing double duty).
- **Use cases** — orchestration (e.g. "capture recipe from text," "convert ingredient units"), depending only on domain protocols, never concrete implementations.
- **Presentation** — thin MVVM view models per screen: hold view state, call use cases, expose results. No business logic in views or view models.

**.NET density API (Clean Architecture, Minimal APIs, no MediatR):** Domain (density entry + validation rules), Application (plain services — "get density entries," "upsert density entry" — no CQRS/MediatR, judged unnecessary ceremony for an API this size), Infrastructure (EF Core, DB, API key enforcement), thin Minimal API endpoint layer on top.

**Testing strategy:**
- Domain + use-case layers (Swift) and Domain + Application layers (.NET): unit tests with fakes, no real persistence.
- Data/Infrastructure layers: integration tests against an in-memory SwiftData store / a real or in-memory test database.
- View models: tested against fake use cases, asserting state transitions (loading/success/error).
- Apple Intelligence capture service: tested via a fake conforming to the same protocol for use-case tests (output isn't fully deterministic); real device checks with sample recipes handled as manual/semi-automated verification, not strict pass-fail units.
- .NET API layer: integration tests against the actual Minimal API endpoints, specifically proving read/write API key enforcement, not just happy-path responses.

**Tooling:** SwiftLint + SwiftFormat on the Swift side, `.editorconfig` + `dotnet format` on the .NET side, both enforced in CI (GitHub Actions) alongside tests and coverage on every push/PR. No specific linter config decided yet — pull one in when it actually comes up rather than pre-deciding.

## Data model

- **Recipe** — title, ingredient lines, steps, source (`typed` or the original URL), tags.
- **Ingredient line** — raw text as entered/extracted, plus (where AI could identify it) structured amount, unit, and ingredient name. The structured fields are what make conversion possible; lines without them show as-is.
- **Tag** — name + flag for built-in preset vs. user-created. Many-to-many with recipes. Presets ship in-app (breakfast, lunch, dinner, dessert, etc.); users can add their own freely.
- **Density entry** — ingredient name → grams-per-cup. Sourced from the .NET API, cached locally on-device.

## Recipe capture

Two clearly presented options on the add-recipe screen — "Type it" or "Paste a link" — so URL support is discoverable, not a hidden trick.

**Typed:** user enters free text, Apple Intelligence structures it into title/ingredients/steps, result lands on an editable review screen before saving. Nothing saves unreviewed.

**URL:** app fetches the page, Apple Intelligence extracts just the recipe (ignoring ads, backstory, comments), same editable review screen.

**No Apple Intelligence available:** skip the AI step, open a blank structured form instead. Same data model, same review screen, just manual entry.

## Unit conversion

Every recipe view has a volume/weight toggle. Switching to weight converts each ingredient line using its density entry, if one is cached locally. If no density value exists for an ingredient, that line shows its original measurement with a small "conversion not available" note — no guessing, no generic estimate substituted in.

## Storage & sync

Single settings choice: **Local** or **iCloud**. Switching to iCloud migrates existing recipes up; switching back keeps a local-only copy on that device. This setting only affects recipes — the density cache is a local performance cache regardless, it doesn't need to sync.

## Backend: density API (.NET)

Hosted on Nick's existing Ubuntu 26.04 VPS. Two access tiers:
- **Read** — low-privilege API key baked into the app, used for fetching/refreshing density entries.
- **Write** — higher-privilege API key held by Nick, used to add/edit entries. No admin UI needed yet; a script is enough for now.

Seeded once from existing public ingredient-density data, then curated by hand over time through the authenticated write endpoints.

**Refresh cadence:** the app checks for new/changed density entries periodically in the background, and also lets the user trigger a manual refresh. Either way, results are cached locally so conversion keeps working offline.

## Implementation plan

Ordered as vertical slices — each phase leaves the app in a working, testable state rather than building all data layer, then all UI, then all AI.

### Phase 1: Foundation
- [x] **1.1 Project scaffold** — new SwiftUI multiplatform app targeting macOS, iPadOS, iOS. One shared codebase, one target per platform.
  Acceptance: app builds and runs on all three platform simulators/destinations with an empty root view.
- [x] **1.2 SwiftData model layer** — `Recipe`, `IngredientLine`, `Tag`, `DensityEntry` models per the data model above, local-only (no CloudKit yet).
  Acceptance: models compile, a recipe with ingredients and tags can be created and fetched in a unit test or preview.
- [ ] **1.3 Recipe list + detail view (read-only)** — basic list of saved recipes, tapping one shows title/ingredients/steps.
  Acceptance: seeding a couple of sample recipes via SwiftData shows them correctly on all three platforms.
- [ ] **1.4 Visual design pass** — define the app's visual identity (color palette, typography, iconography, spacing/layout conventions) and apply it to the recipe list/detail views built in 1.3, replacing default system styling.
  Acceptance: recipe list and detail views reflect a deliberate, documented visual style that reads consistently across macOS, iPadOS, and iOS.

**Checkpoint:** app runs on Mac, iPad, iPhone with the app's visual design applied; sample recipes persist and display. Review before continuing.

### Phase 2: Manual entry & review screen
- [ ] **2.1 Structured entry/edit form** — title, ingredient lines (amount, unit, name, raw text), steps. This is both the no-AI fallback and the review screen every capture path lands on later.
  Acceptance: a recipe can be created, edited, and deleted entirely by hand; changes persist via SwiftData.

**Checkpoint:** full manual CRUD works end-to-end on all platforms.

### Phase 3: Tagging
- [ ] **3.1 Tag model + assignment UI** — preset tags shipped in-app, custom tag creation, multi-tag assignment on the entry/edit form.
  Acceptance: a recipe can carry multiple tags mixing presets and custom ones; tags persist.
- [ ] **3.2 Filter recipe list by tag** — simple filter/segmented control on the list view.
  Acceptance: selecting a tag narrows the list to matching recipes; clearing it restores the full list.

**Checkpoint:** tagging usable end-to-end.

### Phase 4: Settings & iCloud sync
- [ ] **4.1 Settings screen with storage toggle** — Local vs. iCloud choice, wired to SwiftData's CloudKit-backed store.
  Acceptance: switching to iCloud migrates existing recipes and they appear on a second signed-in device/simulator; switching back leaves a local-only copy.

**Checkpoint:** sync verified across two devices/simulators.

### Phase 5: AI-powered capture — typed text
- [ ] **5.1 "Type it" entry point** — text field for pasting/typing a raw recipe, feeds Apple Intelligence to structure it into title/ingredients/steps, lands on the Phase 2 review screen pre-filled.
  Acceptance: typing a real recipe produces a correctly structured, editable result; saving stores it like any manual recipe.
- [ ] **5.2 No-Apple-Intelligence fallback** — detect unsupported devices, skip straight to the blank Phase 2 form.
  Acceptance: on a simulator/device without Apple Intelligence, the "Type it" flow opens the blank form instead of erroring.

**Checkpoint:** typed capture works on supported and unsupported hardware.

### Phase 6: AI-powered capture — URL
- [ ] **6.1 "Paste a link" entry point** — fetch page content, hand to Apple Intelligence to extract just the recipe, land on the same review screen pre-filled.
  Acceptance: pasting a real recipe URL produces a correctly structured, editable result with ads/backstory/comments excluded.
- [ ] **6.2 Add-recipe screen shows both options clearly** — "Type it" / "Paste a link" presented side by side, not hidden.
  Acceptance: both entry points are visible without extra taps from the main add-recipe screen.

**Checkpoint:** both capture paths (typed, URL) confirmed working; full v1 recipe-capture experience done.

### Phase 7: Density API (.NET)
- [ ] **7.1 API scaffold + `DensityEntry` model** — new .NET project (ingredient name → grams-per-cup), basic persistence (Postgres or SQLite, whichever Nick prefers on the VPS).
  Acceptance: API runs locally, entries can be created/read directly against the database.
- [ ] **7.2 Read endpoint + low-privilege key** — public-ish read endpoint gated by a read-only API key.
  Acceptance: requests with a valid read key succeed; requests without one, or with a write key used as read, still succeed only for reads — a request with no key fails.
- [ ] **7.3 Write endpoints + high-privilege key** — add/edit density entries, gated by a separate write key.
  Acceptance: write endpoints reject the read key; only the write key can create/edit entries.

**Checkpoint:** API works locally end-to-end with both key tiers enforced.

### Phase 8: Seed & deploy
- [ ] **8.1 Seed data import** — one-off script loading existing public ingredient-density data into the database.
  Acceptance: common ingredients (flour, sugar, butter, etc.) return sensible density values from the read endpoint.
- [ ] **8.2 Deploy to Ubuntu VPS** — API running as a service on the existing 26.04 VPS, reachable over HTTPS.
  Acceptance: read endpoint reachable from outside the VPS over HTTPS with the read key; write endpoints not reachable without the write key.

**Checkpoint:** API live and seeded; ready for the client to consume.

### Phase 9: Client density integration
- [ ] **9.1 Local density cache** — client fetches entries from the read endpoint and caches them on-device (SwiftData or a lightweight store).
  Acceptance: after one fetch, density lookups work with network off.
- [ ] **9.2 Periodic + manual refresh** — background periodic check for new/changed entries, plus a manual "refresh now" action in Settings.
  Acceptance: adding a new entry via the write API and triggering manual refresh brings it into the app's cache without reinstalling.

**Checkpoint:** density data flows from API to client cache reliably.

### Phase 10: Unit conversion
- [ ] **10.1 Volume/weight toggle on recipe view** — converts each ingredient line using its cached density entry.
  Acceptance: toggling shows correct gram values for ingredients with density data.
- [ ] **10.2 Missing-density fallback** — ingredients without a cached density entry show their original measurement plus a "conversion not available" note instead of a guess.
  Acceptance: an ingredient known to be absent from the density table shows the fallback note, not a fabricated number.

**Checkpoint:** full v1 feature set complete — capture, tag, store/sync, convert.

## Risks and open questions

| Risk | Impact | Mitigation |
|---|---|---|
| Apple Intelligence extraction quality on messy recipe sites | Medium — bad parses land in review screen, so nothing saves silently wrong, but frequent bad parses hurt the "no fluff" promise | Review screen is mandatory by design (Phase 2); revisit prompt/approach if quality is poor in testing |
| CloudKit sync edge cases (conflicts, migration) | Medium — sync bugs are hard to debug later | Test the Local↔iCloud switch explicitly in Phase 4 checkpoint across two devices before moving on |
| Density data coverage gaps | Low — explicitly handled by the fallback note (Phase 10.2) rather than silent wrong answers | None needed beyond the fallback already designed |
| VPS/API becomes a single point of failure for conversion | Low — client caches locally, so downtime only blocks *new* density data, not existing conversions | Local cache (Phase 9.1) already covers this |

## Open items / not yet decided

- Recipe search/browse UX (by tag, by ingredient) — not discussed yet, reasonable default (search + tag filter) assumed but not specced.
- Admin tooling for the density API beyond a basic script.
