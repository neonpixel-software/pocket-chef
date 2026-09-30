# Phase 4.1: Settings screen with storage toggle — design

Source: `PLAN.md` Phase 4.1.

Acceptance (from PLAN.md): switching to iCloud migrates existing recipes and
they appear on a second signed-in device/simulator; switching back leaves a
local-only copy. Checkpoint: sync verified across two devices/simulators.

## Scope decisions

- **Two stores, one at a time.** Recipes live in either the Local store or
  the iCloud store. Each is its own SwiftData `ModelContainer` with its own
  file. The Local store keeps SwiftData's default location
  (`Application Support/default.store`), so recipes already saved on a device
  survive the upgrade. The iCloud store is `Application Support/iCloud.store`,
  backed by the private CloudKit database `iCloud.com.neonpixel.pocketchef`.
- **Every configuration names its CloudKit database explicitly.** With the
  iCloud entitlement present, SwiftData's default `.automatic` would sync
  *any* store, including the Local one. The Local store uses `.none`.
- **Only recipes sync.** The recipe schema is `RecipeModel`,
  `IngredientLineModel` and `TagModel`. `DensityEntryModel` is a local cache
  (PLAN.md "Storage & sync") and moves out of the recipe stores; Phase 10
  gives it its own local-only container. Nothing reads or writes it yet, and
  dropping the entity from the Local store is a lightweight migration.
- **The choice is per device** (`UserDefaults`, not synced). A new device
  starts on Local, and each device opts in.
- **Switching up (Local → iCloud) merges.** Every local recipe is upserted
  into the iCloud store by id. If a recipe with that id already exists, the
  local version overwrites it, because the local version is what the user was
  just looking at. Tags are matched by name, ignoring case. The Local store is
  left as it is (stale, and replaced on the next switch back).
- **Switching back (iCloud → Local) replaces.** The Local store is emptied
  and filled with a snapshot of the iCloud store, so what the user sees
  doesn't change and recipes deleted while syncing stay deleted. iCloud data
  is left alone for the user's other devices. (User decision, 2026-09-30.)
- **The switch applies live, without a relaunch.** Repositories resolve their
  `ModelContext` through a closure onto the current container, so screens
  keep their view models. A `recipeStoreDidChange` notification tells the
  list to reload.
- **Switching up requires an available iCloud account.** The settings view
  model checks `CKContainer.accountStatus()` first and explains why it
  refused (no account, restricted, temporarily unavailable). Switching back
  never needs the account.

## Duplicate tags across devices

CloudKit has no unique constraints, and every device seeds the five preset
tags into its own iCloud store before the first import. After a sync, the
same "Breakfast" arrives twice. `ModelContext.deduplicateTags()` merges tags
whose names match ignoring case and surrounding whitespace:

- It picks the winner deterministically (a preset before a custom tag, then
  the smallest `id.uuidString`). Two devices deduplicating at the same time
  therefore both keep the *same* row, instead of each deleting the other's
  copy and losing both.
- It moves the losers' recipes onto the winner, then deletes the losers.

It runs when the iCloud store opens, on every switch up (before the merge,
so recipes are linked to the row every device keeps, even when the reused
container imported duplicates while in Local mode), and on every
`NSPersistentStoreRemoteChange` notification (a CloudKit import). It saves
only when it found duplicates, so it can't loop. DEBUG sample recipes are
seeded into the Local store only, so debug devices don't push copies of the
sample recipes to iCloud.

## Build configuration (public repo)

- `app/Config/PocketChef.xcconfig` (committed) sets the macOS entitlements
  (App Sandbox + outgoing network, which the Mac App Store requires anyway),
  then `#include? "Signing.xcconfig"`.
- `app/Config/Signing.xcconfig` is **gitignored**. It holds
  `DEVELOPMENT_TEAM`, switches `CODE_SIGN_ENTITLEMENTS` to the iCloud variants
  and adds the `ICLOUD_ENABLED` compilation condition.
  `Signing.xcconfig.example` documents it. (User decision, 2026-09-30.)
- Without `Signing.xcconfig` (CI, a fresh clone) the app builds with no
  iCloud entitlement. Touching CloudKit without the entitlement raises an
  Objective-C exception, so `ICLOUD_ENABLED` gates the account check, and the
  settings picker is disabled with a note. A stored `.iCloud` preference is
  ignored in such a build.
- iOS also gets `UIBackgroundModes: remote-notification` (CloudKit's silent
  push) through an XcodeGen-generated partial Info.plist that is merged with
  the generated one.

Sandboxing moves the macOS app's data into its container, so recipes saved
by the unsandboxed dev builds don't carry over on the Mac (DEBUG reseeds the
samples). No release has shipped, so no user data is affected.

## Layers

- **Domain:** `StorageMode` (`.local` / `.iCloud`), `ICloudAccountStatus`,
  protocols `StorageModeSwitcher` (current mode + `switchTo(_:)`) and
  `ICloudAccountStatusProvider`, and `ChangeStorageModeUseCase` (checks the
  account when going up, then switches; `StorageModeError.iCloudUnavailable`).
- **Data:** `RecipeStoreCopier` (merge / replace between two contexts),
  `ModelContext.deduplicateTags()`, `RecipeStore` (builds the container for a
  mode), `PersistenceController` (holds the current container, caches one
  container per mode for the session, persists the preference, observes
  remote changes), `CloudKitAccountStatusProvider`.
- **Presentation:** `SettingsView` + `SettingsViewModel`. On iOS/iPadOS a gear
  button in the recipe list toolbar opens it as a sheet. On macOS it's the
  standard Settings window (⌘,).

## Known limits

- **Snapshot during the first import.** A switch back while the first
  CloudKit import is still running copies only what has arrived so far.
- **Mirroring runs until relaunch.** Once the iCloud container has been
  opened in a session, it stays open until relaunch, even after a switch back
  to Local, because opening the same CloudKit store twice in one process
  breaks mirroring. It keeps importing in the background until the app quits,
  but local edits go to the Local store and never upload.
- **Production schema.** Before the first CloudKit-enabled release, deploy
  the development schema to production (PLAN.md 4.1 note, Phase 12).
- **An open detail screen can overwrite a newer remote edit.** The detail
  view model holds a `Recipe` value and doesn't reload on
  `recipeStoreDidChange`. If an import changes that recipe while its detail
  screen is open, saving there overwrites the remote version (last write
  wins, by id). This comes with the value-based detail screen and only
  matters now that recipes sync. Fix by reloading the detail's recipe on
  `recipeStoreDidChange` if it shows up in practice.
- **The switch runs on the main thread.** The copy (fetch, map, save in both
  stores) runs on the main context. That's fine for a personal recipe
  collection; for large libraries, move the copy to a background context.
- **Switching up means the local version wins.** A recipe that exists in both
  stores (same id) takes the local version, even if the iCloud copy is newer.
  That only happens after switching up, back and up again on one device, and
  the local copy is what the user was just looking at.

## Findings from the device check (2026-09-30)

- **The Mac app must link CloudKit directly.** A sandboxed Mac test app that relied only on
  SwiftData's CloudKit sync was denied the CloudKit daemon by the sandbox
  (`deny mach-lookup com.apple.cloudd`, CKError 6). It started syncing as soon as it linked
  CloudKit. Pocket Chef links it through `CloudKitAccountStatusProvider`.
- **Pushes to the Mac are slow in development.** Uploads work both ways, and the iPhone gets
  the Mac's changes within seconds. CloudKit's pushes for iPhone changes reached the Mac
  5.5–9.5 minutes late, and some never arrived. A minimal control app (plain
  `.modelContainer` + `@Query`, same app ID, container and models, none of Pocket Chef's
  code) behaved the same way, so this isn't caused by the store switching or the refresh
  code. On the Mac, changes arrive at once when the app is launched or brought to the front,
  and when it uploads an edit (every upload fetches first).

## Verification

- Unit tests: the copier (merge upserts by id, tag matching by name, replace
  empties first), tag deduplication (winner rule, recipe reassignment, no
  save when clean), the use case (account gate, no-op on same mode), the
  settings view model states, and the persistence controller switching
  between in-memory stores.
- On devices: sign in with the same Apple ID on the Mac and an iPhone, switch
  both to iCloud, add or edit a recipe on one, and check it appears on the
  other. Switch one back to Local and check that its recipes are still there
  and edits no longer sync.
