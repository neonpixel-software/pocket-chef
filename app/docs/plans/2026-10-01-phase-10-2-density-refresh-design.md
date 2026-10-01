# Phase 10.2: Periodic + manual refresh — design

Source: `PLAN.md` Phase 10.2. Builds on 10.1
(`2026-10-01-phase-10-1-density-cache-design.md`).

Acceptance (from PLAN.md): adding a new entry via the write API and
triggering manual refresh brings it into the app's cache without
reinstalling.

## Scope decisions

- **"Periodic" means a daily check whenever the app becomes active, not an
  OS background task.** When the app comes to the foreground (including
  launch), it refreshes if the last successful refresh is more than 24 hours
  old, or if there has never been one. `BGAppRefreshTask` is iOS-only, the
  system runs it when it chooses (often rarely), and it needs extra
  Info.plist and capability setup. The data changes rarely and is only needed
  while the app is open, so a check on activation covers it on both platforms.
  The 10.1 "fetch only when empty" launch path goes away: an empty cache
  counts as stale.
- **Manual refresh lives in Settings.** A new "Ingredient Densities" section
  shows when the data was last updated, a "Refresh Now" button, and the
  result: up to date, updated, or a connection error. Builds without the API
  configuration show the section disabled with an explanation, like iCloud.
- **Diff instead of replace.** A refresh still downloads the full table (see
  the PLAN.md note), but it applies the difference against the cache. Entries
  whose key is new are inserted. Entries whose `lastModified` or density
  changed are updated. Cached entries missing from the response are deleted.
  It saves only when something changed, and reports the counts
  (`DensityCacheChanges`). Settings shows only whether anything changed, so it
  needs no plural strings.
- **One refresh at a time.** Activation and a manual tap can overlap. While a
  refresh runs, another request waits for it and gets its result, instead of
  starting a second download.
- **The last refresh time is per device**, in `UserDefaults`, and only a
  successful refresh records it. A failed refresh leaves the cache alone, and
  the next activation tries again.

## Components

Domain:
- `DensityCacheRepository.replaceAll(with:)` becomes `apply(_:) ->
  DensityCacheChanges`. `isEmpty()` stays.
- `DensityRefreshLog` (`lastRefresh`, `recordRefresh(at:)`), backed by
  `UserDefaults`.
- `RefreshDensityCacheUseCase`: `execute()` (manual; always downloads),
  `executeIfStale()` (activation), and `lastRefresh`. It takes a clock, so
  tests control the 24-hour boundary.

Presentation:
- `SettingsViewModel` gets an optional refresh use case (nil without the
  configuration), plus `lastDensityRefresh`, `isRefreshingDensities` and a
  status message.
- `SettingsView` adds the section. The date shows as relative time ("2 hours
  ago").
- New strings get catalog entries in es/fr/de/nl. They still need the
  native-speaker pass (#65).

App: `PocketChefApp` calls `executeIfStale()` when the scene phase becomes
`.active`.

## Verification

- Unit tests: the diff (insert, update on a newer `lastModified`, delete,
  nothing changed means no save), staleness (never refreshed, under and over
  24 hours, empty cache), the single-flight guard, failures not recording a
  refresh, the Settings view model states, and string catalog coverage.
- Acceptance against production needs a write. The options are to add one
  real entry with the write key and press Refresh Now in the simulator, or
  to run the API locally. Which one is the user's call.
