# Phase 13: Recipe photos — design

Source: `PLAN.md` Phase 13 (added 2026-10-07, before the first release).

Goal: a recipe can hold photos the user adds from the photo library or takes
with the camera. The first photo is the recipe's cover. Photos sync with the
recipe when storage is set to iCloud.

## Scope decisions (user, 2026-10-07)

- **A gallery with a cover.** A recipe has any number of photos, in order.
  The first one is the cover: it's the list thumbnail and the first page of
  the detail gallery. A recipe without photos looks exactly like it does
  today.
- **No limit on the number of photos.** Each photo is scaled down to at most
  2048 px on its long edge before it's saved (about 0.5 MB as JPEG), so a
  large gallery doesn't fill the user's iCloud storage. Originals are not
  kept.
- **Sources: photo library and camera.** The photo library is available on
  every platform. The camera is offered only on iPhone and iPad, and only
  when the device has one. Not in scope: importing files, drag and drop, and
  downloading the image of a captured recipe URL.
- **Photos are managed in the edit form.** The detail screen only shows them.
  Photo changes save or cancel together with the rest of the recipe, like
  every other field.
- **Reordering uses buttons, not dragging.** Each thumbnail has Make Cover,
  Move Left, Move Right and Delete. The form already reorders ingredients and
  steps with buttons, and the UI tests can't rely on mouse drags on the
  GitHub macOS runner.

## Why now

Photos add a CloudKit record type (`CD_RecipePhotoModel`). Once 12.4 deploys
the CloudKit schema to production, it can only grow (no renames or removals),
so the photo model should land before that deploy.

## Storage

Photos are their own SwiftData model, with the bytes in external storage:

```swift
@Model
final class RecipePhotoModel {
    var id: UUID = UUID()
    /// Index in the recipe's gallery; 0 is the cover. SwiftData doesn't keep
    /// the order of to-many relationships.
    var position: Int = 0
    @Attribute(.externalStorage) var imageData: Data?
    @Attribute(.externalStorage) var thumbnailData: Data?
    @Relationship(inverse: \RecipeModel.photos) var recipe: RecipeModel?
}
```

- `RecipeModel` gets `@Relationship(deleteRule: .cascade) var photos: [RecipePhotoModel]? = []`.
- `RecipeStore.schema` adds `RecipePhotoModel.self`. Existing stores migrate
  lightweight (an empty relationship).
- External storage keeps the bytes out of the SQLite rows, and CloudKit
  uploads them as `CKAsset`s, so record size limits (1 MB) don't apply.
- `RecipeStoreCopier.merge` and `.replace` copy photos with their bytes and
  positions, so switching between Local and iCloud keeps them.

Rejected alternatives:

- **Files in an iCloud Drive container.** A second sync mechanism to keep in
  step with the CloudKit records by hand (conflicts, partial downloads,
  deletes), with no gain.
- **Bytes on `RecipeModel`.** Breaks CloudKit's 1 MB record limit after a few
  photos, and loads every photo whenever a recipe loads.

## Domain

- `struct RecipePhoto: Identifiable, Equatable { let id: UUID; var position: Int }`.
  No image bytes: `RecipeRepository.fetchAll()` maps every recipe, and the
  list must not load photos.
- `Recipe` gets `var photos: [RecipePhoto] = []`, sorted by position.
  `recipe.photos.first` is the cover.
- `protocol RecipePhotoRepository` loads bytes on demand:
  `thumbnail(id:) throws -> Data?` and `image(id:) throws -> Data?`.
  `nil` means the bytes aren't on this device (yet).
- New photo bytes travel with the save: the form passes a
  `[UUID: ProcessedPhoto]` map (image + thumbnail) alongside the `Recipe` to
  the create and update use cases. The repository inserts models for new
  ids, deletes models whose id is no longer in `recipe.photos`, and rewrites
  positions.
- `protocol PhotoProcessor` turns picked or captured image data into a
  `ProcessedPhoto`. The Data implementation, `ImageIOPhotoProcessor`:
  - runs off the main actor;
  - decodes with ImageIO and applies the EXIF orientation;
  - scales down (never up) to 2048 px on the long edge, plus a 300 px thumbnail;
  - encodes both as JPEG (quality 0.8) without metadata, so no location or
    camera details are stored (the app collects no user data);
  - throws `PhotoProcessingError.unreadableImage` for data ImageIO can't decode.

## UI

### List

- With photos, `RecipeRow` shows the cover thumbnail on the left: 56×56 pt,
  rounded corners, filled and cropped. Rows without photos are unchanged
  (no placeholder).
- Each row loads its thumbnail lazily through `RecipePhotoRepository`, with a
  small in-memory cache.

### Detail

- With photos, a gallery sits at the top of the scroll view, above the tags:
  about 4:3, rounded corners, cover first, page dots when there's more than
  one photo. iOS uses a paged `TabView`; the Mac uses a snapping horizontal
  `ScrollView` with arrow buttons.
- Tapping a photo opens a full-screen viewer: pinch to zoom, swipe between
  photos, Done.

### Form

- A Photos section, in the existing `formSection` style, under the title and
  above Ingredients.
- A strip of 80 pt thumbnails; the first has a "Cover" badge.
- An Add Photo button ends the strip. On iPhone and iPad it's a menu (Photo
  Library, Take Photo); on the Mac it opens the photo picker directly.
- Each thumbnail's context menu: Make Cover, Move Left, Move Right, Delete.
  The same actions are exposed as accessibility actions.
- Picked photos are processed right away, each with its own spinner, and kept
  in memory until Save. Cancel discards them. Save is disabled while any
  photo is still processing.

### Accessibility and localization

- VoiceOver labels: "Cover photo", "Photo 2 of 5".
- New strings in en, de, es, fr and nl; the nl/es drafts are added to #65 for
  native-speaker review.

## Photo library and camera

- **Library:** SwiftUI `PhotosPicker`, `matching: .images`, no selection
  limit, `preferredItemEncoding: .compatible`. It runs out of process, so the
  app needs no photo library permission. Items load through
  `loadTransferable(type: Data.self)`, which downloads iCloud Photos
  originals that aren't on the device.
- **Camera:** a small `UIImagePickerController` wrapper (`.camera`) shown full
  screen, offered only when `UIImagePickerController.isSourceTypeAvailable(.camera)`
  (so never in the simulator or on the Mac).
  - `Info-iOS.plist` gets `NSCameraUsageDescription` ("Pocket Chef uses the
    camera to add photos to your recipes."), localized through a new
    `InfoPlist.xcstrings` in the five languages.
  - When camera access was denied, Take Photo shows an alert with Open
    Settings.
  - Camera photos are stored only in the recipe, not in the photo library, so
    no library write permission is needed.

## Errors

- A photo that fails to load or decode is dropped from the strip, and the
  Photos section shows "A photo couldn't be added." The other photos and the
  rest of the form are unaffected.
- A missing thumbnail or image (CloudKit hasn't downloaded the asset to this
  device yet) shows a neutral placeholder with a photo icon and reloads on
  `.recipeStoreDidChange`.
- Deleting a photo or a recipe removes the external storage files through the
  cascade delete; CloudKit deletes the records on other devices.

## Testing

Unit tests (the 90% coverage gate applies):

- Mapping: position ordering, round trip, cascade delete.
- `SwiftDataRecipePhotoRepository`: thumbnail and image loading, `nil` for an
  unknown id.
- Create/update: new photos inserted, removed ones deleted, positions
  rewritten.
- `RecipeStoreCopier`: merge and replace carry photos with bytes and order.
- `ImageIOPhotoProcessor` with fixtures (landscape JPEG, portrait HEIC with
  EXIF orientation 6, a small PNG, junk data): long edge ≤ 2048, thumbnail
  ≤ 300, orientation applied, no EXIF/GPS left, no upscaling, junk throws.
- `RecipeFormViewModel` with a fake processor: add, delete, Make Cover,
  Move Left/Right, Save disabled while processing, Cancel discards, a
  failure shows the inline message.

UI tests (existing iOS/macOS targets): a `-UITestScenario recipeWithPhotos`
seeding three bundled images. The list row shows a thumbnail, the detail
gallery has page labels, and the form shows the Cover badge and reorders
through Make Cover (an accessibility action, not a click). The camera and
`PhotosPicker` are system UI and get a manual check instead.

Manual device check (Mac + iPhone 12, iCloud mode): add from the library on
both, take a photo on the iPhone, photos and their deletion/reordering sync
both ways, the cover shows in the list, a Local ↔ iCloud switch keeps photos,
and a 10-photo recipe takes about 5 MB.

## Delivery

Three PRs, each shippable on its own:

1. **13.1 Data model and domain:** `RecipePhotoModel`, schema, mapping,
   copier, `RecipePhotoRepository`, `ImageIOPhotoProcessor`, use case
   changes, tests. No UI.
2. **13.2 Adding and arranging photos:** the form's Photos section, the
   photo library picker, the camera, `InfoPlist.xcstrings`, strings.
3. **13.3 Showing photos:** list thumbnail, detail gallery, full-screen
   viewer, UI tests, the device check.
