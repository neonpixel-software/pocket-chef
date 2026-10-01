# Phase 10.1: Local density cache — design

Source: `PLAN.md` Phase 10.1.

Acceptance (from PLAN.md): after one fetch, density lookups work with the
network off.

## Scope decisions

- **Its own local-only store.** Density entries live in a separate SwiftData
  container, `Application Support/density.store`, with `cloudKitDatabase:
  .none`. The recipe stores don't include `DensityEntryModel` (Phase 4.1), so
  the cache never syncs and the iCloud schema doesn't change. The data can
  always be downloaded again, so it doesn't need to be backed up or synced.
- **The full table replaces the cache.** `GET /density-entries` returns every
  entry (72 rows from SR Legacy today), so a refresh deletes the cached rows and
  inserts the response in one save. Entries removed on the server disappear
  from the cache. Diffing by `lastModifiedUtc` is a 10.2 concern (PLAN.md).
- **When it fetches (10.1).** At launch, only if the cache is empty. A failed
  fetch is logged and retried at the next launch. Periodic and manual
  refresh are 10.2.
- **Lookup is by a normalized key.** The API stores names canonicalized with
  `IngredientNames.Canonicalize` (NFC + trim), and its citext index folds case
  (issue #55). The client's key does the same: NFC, trim whitespace and
  newlines, lowercase. Each cached row stores the key as a unique attribute
  (allowed, since the store doesn't use CloudKit), so a lookup is one indexed
  fetch. Matching a recipe's ingredient line (e.g. "2 cups flour") to an
  entry is Phase 11; 10.1 matches whole names only.
- **The domain model follows the API.** `DensityEntry` drops its unused `UUID`
  (the API doesn't expose ids) and gains `lastModified`, so 10.2 can diff
  against it. It's identified by its lookup key.

## Configuration (public repo)

The API host and read key must not be committed (the repo is public, and the
host is kept out of it; see `api/docs/deploy.md`).

- `app/Config/DensityAPI.xcconfig` is **gitignored** and sets
  `DENSITY_API_HOST` (host only: `//` starts a comment in an xcconfig) and
  `DENSITY_API_READ_KEY`. `DensityAPI.xcconfig.example` documents it.
  `Config/PocketChef.xcconfig` includes it with `#include?`.
- Both Info.plists (`Info-iOS.plist`, and a new `Info-macOS.plist`) carry
  `DensityAPIHost = $(DENSITY_API_HOST)` and `DensityAPIReadKey =
  $(DENSITY_API_READ_KEY)`. Without the xcconfig, the values expand to empty
  strings.
- `DensityAPIConfiguration.init?(bundle:)` reads them and returns nil when
  either is empty. Then the app skips the fetch and lookups find nothing.
  GitHub CI builds this way, since its tests use stubs.
- Xcode Cloud: `ci_post_clone.sh` writes the xcconfig from the secret workflow
  variables `DENSITY_API_HOST` and `DENSITY_API_READ_KEY`, like
  `DEVELOPMENT_TEAM`.
- The read key ships inside the app binary, which is what the read tier is
  for: it can only read public reference data and is rate-limited. The write
  key never leaves the Mac or the deploy secrets.

## Components

Domain:
- `DensityEntry` (ingredientName, gramsPerMilliliter, lastModified; `id` is the
  lookup key) and `DensityEntry.lookupKey(for:)`.
- `DensityEntryRemoteSource` (`fetchAll() async throws -> [DensityEntry]`).
- `DensityCacheRepository` (`replaceAll(with:)`, `entry(forIngredientNamed:)`,
  `isEmpty()`).
- `RefreshDensityCacheUseCase`: `execute()` always fetches and replaces;
  `executeIfCacheEmpty()` is the launch path.
- `LookUpDensityUseCase`: name → `DensityEntry?`. Phase 11 uses it.

Data:
- `DensityStore.makeContainer()` and `DensityEntryModel` (now keyed by
  `lookupKey`).
- `SwiftDataDensityCacheRepository`.
- `URLSessionDensityEntryRemoteSource`: `GET https://<host>/density-entries`
  with `X-Api-Key`, checks for HTTP 200, and decodes the camelCase JSON.
  `lastModifiedUtc` is ISO 8601 with up to 7 fractional digits (.NET). It
  takes a `URLSession`, so tests stub the network with a `URLProtocol`.

App: `PocketChefApp` builds the store and starts `executeIfCacheEmpty()` in a
task at launch, if the configuration exists.

## Verification

- Unit tests: key normalization (case, whitespace, NFC vs NFD), the
  repository (replace removes stale rows, unique keys, lookup), both use-case
  paths, and the remote source (header, URL, status errors, decoding, a
  `URLError` while offline). The acceptance test refreshes from a stub, then
  looks up with a remote source that throws `.notConnectedToInternet`.
- On the Mac with a real `DensityAPI.xcconfig`: launch once online (the cache
  fills from production), then launch with networking off and confirm the
  cache still answers lookups.
