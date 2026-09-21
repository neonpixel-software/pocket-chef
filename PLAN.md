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

**Tooling:** SwiftLint + SwiftFormat on the Swift side, `.editorconfig` + `dotnet format` on the .NET side, both enforced in CI (GitHub Actions) alongside tests and coverage on every push/PR. The configs are checked in (`app/.swiftformat`, `app/.swiftlint.yml`, `api/.editorconfig`) and written to match the conventions each codebase already uses rather than re-styling it (issue #51); CI pins the tool version each config was validated against.

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

## Licensing

**MIT**, one root `LICENSE` covering the whole repo (`app/` + `api/`).

The repo originally shipped as GPL-3.0, which conflicts with the App Store: Apple's distribution terms (no redistribution of modified copies, DRM/signing lock-in) are incompatible with the freedoms GPLv3 grants, and the FSF documents the App Store as an unsupported channel for GPLv3 software. On iOS/iPadOS the App Store is effectively the only realistic distribution route, so this had to be resolved before Phase 4's sync work and the eventual store submission (issue #46).

MIT rather than Apache 2.0 — both are permissive and resolve the App Store conflict, the only substantive difference being Apache's patent grant: at solo-author scale that clause is dormant, MIT is the more idiomatic choice in the Swift/App Store ecosystem, and it's the shortest license (least friction for anyone adopting or vendoring pieces). Revisit the choice if the project ever grows a team of contributors.

One license for the whole monorepo: the API is never distributed via the App Store (own VPS, own app), but a per-component split would only add maintenance surface for no benefit. Relicensed as sole copyright holder — no third-party contributions existed, so no consents were needed; the repo's earlier commits retain the old GPL-3.0 `LICENSE` in git history.

## Implementation plan

Ordered as vertical slices — each phase leaves the app in a working, testable state rather than building all data layer, then all UI, then all AI.

### Phase 1: Foundation
- [x] **1.1 Project scaffold** — new SwiftUI multiplatform app targeting macOS, iPadOS, iOS. One shared codebase, one target per platform.
  Acceptance: app builds and runs on all three platform simulators/destinations with an empty root view.
- [x] **1.2 SwiftData model layer** — `Recipe`, `IngredientLine`, `Tag`, `DensityEntry` models per the data model above, local-only (no CloudKit yet).
  Acceptance: models compile, a recipe with ingredients and tags can be created and fetched in a unit test or preview.
- [x] **1.3 Recipe list + detail view (read-only)** — basic list of saved recipes, tapping one shows title/ingredients/steps.
  Acceptance: seeding a couple of sample recipes via SwiftData shows them correctly on all three platforms.
- [x] **1.4 Visual design pass** — define the app's visual identity (color palette, typography, iconography, spacing/layout conventions) and apply it to the recipe list/detail views built in 1.3, replacing default system styling.
  Acceptance: recipe list and detail views reflect a deliberate, documented visual style that reads consistently across macOS, iPadOS, and iOS.

**Checkpoint:** app runs on Mac, iPad, iPhone with the app's visual design applied; sample recipes persist and display. Review before continuing.

### Phase 2: Manual entry & review screen
- [x] **2.1 Structured entry/edit form** — title, ingredient lines (amount, unit, name, raw text), steps. This is both the no-AI fallback and the review screen every capture path lands on later.
  Acceptance: a recipe can be created, edited, and deleted entirely by hand; changes persist via SwiftData.

**Checkpoint:** full manual CRUD works end-to-end on all platforms.

### Phase 3: Tagging
- [x] **3.1 Tag model + assignment UI** — preset tags shipped in-app, custom tag creation, multi-tag assignment on the entry/edit form.
  Acceptance: a recipe can carry multiple tags mixing presets and custom ones; tags persist.
- [x] **3.2 Filter recipe list by tag** — simple filter/segmented control on the list view.
  Acceptance: selecting a tag narrows the list to matching recipes; clearing it restores the full list.

**Checkpoint:** tagging usable end-to-end.

### Phase 4: Settings & iCloud sync
- [ ] **4.1 Settings screen with storage toggle** — Local vs. iCloud choice, wired to SwiftData's CloudKit-backed store.
  Acceptance: switching to iCloud migrates existing recipes and they appear on a second signed-in device/simulator; switching back leaves a local-only copy.
  Note: the model schema (`RecipeModel`, `IngredientLineModel`, `TagModel`, `DensityEntryModel`) was reworked ahead of this phase (issue #48) to be CloudKit-compatible — no `.unique` attributes, every attribute has a default, every relationship is optional with an inverse declared on both sides. Verified via a regression test (`CloudKitSchemaCompatibilityTests`) that loads all four models into a CloudKit-backed `ModelContainer` without throwing. Still open for this phase: the actual dual `ModelConfiguration` (plain store + CloudKit-backed store) plus data-copy routine for the Local↔iCloud toggle, and the CloudKit prerequisites (Apple Developer account, iCloud capability in `project.yml`, container registration for `com.neonpixel.pocketchef`) — none of that is wired up yet.

**Checkpoint:** sync verified across two devices/simulators.

### Phase 5: AI-powered capture — typed text
- [ ] **5.1 "Type it" entry point** — text field for pasting/typing a raw recipe, feeds Apple Intelligence to structure it into title/ingredients/steps, lands on the Phase 2 review screen pre-filled.
  Acceptance: typing a real recipe produces a correctly structured, editable result; saving stores it like any manual recipe.
  All code/tests/UI built and passing; left unchecked because the actual on-device AI extraction quality hasn't been verified — no development machine here has Apple Intelligence enabled. Check off once verified on a real device.
- [x] **5.2 No-Apple-Intelligence fallback** — detect unsupported devices, skip straight to the blank Phase 2 form.
  Acceptance: on a simulator/device without Apple Intelligence, the "Type it" flow opens the blank form instead of erroring.

**Checkpoint:** typed capture works on supported and unsupported hardware.

### Phase 6: AI-powered capture — URL
- [ ] **6.1 "Paste a link" entry point** — fetch page content, hand to Apple Intelligence to extract just the recipe, land on the same review screen pre-filled.
  Acceptance: pasting a real recipe URL produces a correctly structured, editable result with ads/backstory/comments excluded.
  All code/tests/UI built and passing; left unchecked because the actual on-device AI extraction quality hasn't been verified — no development machine here has Apple Intelligence enabled. Check off once verified on a real device (same constraint as 5.1).
- [x] **6.2 Add-recipe screen shows both options clearly** — "Type it" / "Paste a link" presented side by side, not hidden.
  Acceptance: both entry points are visible without extra taps from the main add-recipe screen.

**Checkpoint:** both capture paths (typed, URL) confirmed working; full v1 recipe-capture experience done.

### Phase 7: Localization
- [ ] **7.1 String Catalog + automatic UI string resolution** — `Localizable.xcstrings` covering every user-facing UI string (45 keys across list/form/detail/capture screens), translated to Spanish, French, German, and Dutch alongside the English base.
  Acceptance: switching the device/simulator language to any of the four translated locales shows translated UI chrome with no raw fallback keys or obviously broken layout. Manually verified on this Mac in Spanish and German (list, add-recipe chooser, recipe form) — no missing entries, no layout breakage, umlauts render fine. Left unchecked because translations are machine-generated in this environment and need a fluent-speaker quality pass before shipping — mechanism is verified here, not translation quality.
- [x] **7.2 Preset tag names localized, user tags untouched** — the 5 shipped preset tags (Breakfast, Lunch, Dinner, Dessert, Snack) display in the device's language via a stable English matching key; any tag a user creates or renames displays exactly as typed, never translated.
  Acceptance: a preset tag's display name changes with device language; a custom or renamed tag's name does not. Verified manually in Spanish and German: presets translated (e.g. "Frühstück"), the custom "Refreshing" sample tag stayed in English in both.
- [ ] **7.3 View-model error messages localized** — the 3 capture-failure messages in `RecipeCaptureViewModel`/`RecipeURLCaptureViewModel` resolve via the same String Catalog.
  Acceptance: triggering a capture failure while the device language is set to a translated locale shows the translated message, not English. Catalog entries are unit-tested directly and confirmed correct (`LocalizedCaptureErrorMessagesTests`), but actually triggering these messages in the running app needs a real capture attempt — blocked by the same no-Apple-Intelligence constraint as 5.1/6.1 on this Mac (the capture screens never open here; the unavailable-alert shows instead). Check off once verified on a real device.

**Checkpoint:** app fully navigable in English, Spanish, French, German, and Dutch; mechanism verified manually, translation quality flagged for human review before ship.

### Phase 8: Density API (.NET)
- [x] **8.1 API scaffold + `DensityEntry` model** — new .NET project (ingredient name → grams-per-cup), basic persistence. PostgreSQL chosen (via Docker/Podman), not SQLite.
  Acceptance: API runs locally, entries can be created/read directly against the database. Verified end-to-end: real migration applied to a locally running Postgres (via Podman), entry inserted and read back via `psql`, the `/health` endpoint responds, and the Dockerfile image builds and runs correctly against the same Postgres.
  `nuget` ecosystem entry added to `.github/dependabot.yml`.
- [x] **8.2 Read endpoint + low-privilege key** — public-ish read endpoint gated by a read-only API key.
  Acceptance: requests with a valid read key succeed; requests without one, or with a write key used as read, still succeed only for reads — a request with no key fails. Verified via automated tests (unit + `WebApplicationFactory` integration tests covering all four cases) and manually end-to-end against the real running app and a real local Postgres.
- [x] **8.3 Write endpoints + high-privilege key** — add/edit density entries, gated by a separate write key.
  Acceptance: write endpoints reject the read key; only the write key can create/edit entries. Verified via automated tests (`WebApplicationFactory` integration tests covering no key/read key/valid write key/invalid body, plus Testcontainers-backed insert and update-in-place cases) and manually end-to-end against the real running app and a real local Postgres via Podman — confirmed via `psql` that an upsert to an existing ingredient name updates the row in place rather than duplicating it.

**Checkpoint:** API works locally end-to-end with both key tiers enforced.

### Phase 9: Seed & deploy
- [ ] **9.1 Seed data import** — one-off script loading existing public ingredient-density data into the database.
  Acceptance: common ingredients (flour, sugar, butter, etc.) return sensible density values from the read endpoint.
- [ ] **9.2 Deploy to Ubuntu VPS** — API running as a service on the existing 26.04 VPS, reachable over HTTPS.
  Acceptance: read endpoint reachable from outside the VPS over HTTPS with the read key; write endpoints not reachable without the write key.
  Note: TLS termination (via the VPS's existing nginx + certbot), production key storage, Postgres backups, and process supervision are documented in `api/docs/deploy.md` (issue #47). A fixed-window rate limiter on the read endpoint (60 req/min, since the read key ships inside the app binary and is extractable) is already implemented and covered by `DensityEntriesRateLimitTests`. Still open: actually running this runbook against the real VPS — needs whoever has access to it.

**Checkpoint:** API live and seeded; ready for the client to consume.

### Phase 10: Client density integration
- [ ] **10.1 Local density cache** — client fetches entries from the read endpoint and caches them on-device (SwiftData or a lightweight store).
  Acceptance: after one fetch, density lookups work with network off.
- [ ] **10.2 Periodic + manual refresh** — background periodic check for new/changed entries, plus a manual "refresh now" action in Settings.
  Acceptance: adding a new entry via the write API and triggering manual refresh brings it into the app's cache without reinstalling.
  Note: `DensityEntryResponse` already includes `lastModifiedUtc` on every entry (added ahead of this phase, after review flagged that adding it later would mean a schema migration plus an API contract change at the same time a client already depends on the shape). "New/changed" can be detected by diffing against the client's cached `lastModifiedUtc` per ingredient without needing a dedicated `?since=` endpoint — revisit only if the full-table `GET` stops being cheap enough at real seeded-data scale.

**Checkpoint:** density data flows from API to client cache reliably.

### Phase 11: Unit conversion
- [ ] **11.1 Volume/weight toggle on recipe view** — converts each ingredient line using its cached density entry.
  Acceptance: toggling shows correct gram values for ingredients with density data.
- [ ] **11.2 Missing-density fallback** — ingredients without a cached density entry show their original measurement plus a "conversion not available" note instead of a guess.
  Acceptance: an ingredient known to be absent from the density table shows the fallback note, not a fabricated number.

**Checkpoint:** full v1 feature set complete — capture, tag, store/sync, convert.

### Phase 12: Release & distribution
- [ ] **12.1 App Store Connect setup + App Privacy labels** — register the app in App Store Connect and complete the mandatory App Privacy labels. The labels must be truthful: this app collects no user data (see the plan's privacy stance above), so the declaration is "data not collected".
  Acceptance: privacy labels submitted and passing review with a truthful no-data-collection declaration for all three platforms.
- [ ] **12.2 Store assets** — app icon plus per-platform screenshot sets at every required size (macOS, iPadOS, iOS), built from real app captures, not mockups.
  Acceptance: every required screenshot slot for each platform is filled and renders correctly in a TestFlight build.
- [ ] **12.3 Versioning, signing, notarization** — version/scheme management, signing identities, and a macOS notarization flow wired into a single command or CI job, so producing a distributable build is one step.
  Acceptance: one command produces a signed, notarized macOS build and an App Store build for iOS/iPadOS.
- [ ] **12.4 TestFlight → production rollout** — internal testing, then beta, then public release, with a short runbook for what to verify at each stage.
  Acceptance: v1 live in the public App Store on all three platforms.

**Checkpoint:** Pocket Chef is publicly available on the App Store (macOS, iPadOS, iOS).

## Risks and open questions

| Risk | Impact | Mitigation |
|---|---|---|
| Apple Intelligence extraction quality on messy recipe sites | Medium — bad parses land in review screen, so nothing saves silently wrong, but frequent bad parses hurt the "no fluff" promise | Review screen is mandatory by design (Phase 2); revisit prompt/approach if quality is poor in testing |
| CloudKit sync edge cases (conflicts, migration) | Medium — sync bugs are hard to debug later | Schema made CloudKit-compatible ahead of Phase 4 (issue #48), while no real user data exists, avoiding a later local-store migration; test the Local↔iCloud switch explicitly in Phase 4 checkpoint across two devices before moving on |
| Density data coverage gaps | Low — explicitly handled by the fallback note (Phase 11.2) rather than silent wrong answers | None needed beyond the fallback already designed |
| Density Postgres data loss on the VPS (disk failure, accidental drop) | Low — the density table is small, hand-curated data, not user data; re-seeding from Phase 9.1's source is a viable fallback | Nightly `pg_dump` backup documented in `api/docs/deploy.md` (issue #47) |
| VPS/API becomes a single point of failure for conversion | Low — client caches locally, so downtime only blocks *new* density data, not existing conversions | Local cache (Phase 10.1) already covers this |

## Open items / not yet decided

- Recipe search/browse UX (by tag, by ingredient) — not discussed yet, reasonable default (search + tag filter) assumed but not specced.
- Admin tooling for the density API beyond a basic script.
- If Swift Package Manager dependencies are ever added (a `Package.swift` shows up), add a `swift` ecosystem entry to `.github/dependabot.yml` — not there yet since there's nothing for it to check.
