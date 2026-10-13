# Rollout: TestFlight to the App Store

PLAN 12.4. What to do and check at each stage of a release, after `release.md` has produced the
builds. Stages 0 and 4 also apply to later releases; the one-time steps are marked.

Each stage has a gate: don't move on until every check passes. If one fails, fix it on `main`, bump
the version (`release.md`) and start the stage again with the new build.

## Stage 0: before tagging

**CloudKit production schema (one-time, before the first release).** Release builds sync through
the production CloudKit environment, which starts empty, so the app can't save to iCloud until the
schema is deployed there. Once it's deployed, fields can only be added, never renamed or removed
(PLAN 4.1), so deploy it with everything the first release needs.

CloudKit adds a field to the development schema only when a record with that field filled in
syncs. So first fill in every field once:

1. Run a development build with iCloud on (`icloud-sync-testing` notes: `Signing.xcconfig`, a real
   device) and add one recipe that sets every synced field:
   - from **Paste a Link**, so it has a `sourceURL`
   - with an ingredient that has an amount, a unit and a name (e.g. "2 cups flour")
   - with equipment, steps, a preset tag and a custom tag
   - with two photos, so the image and thumbnail assets and positions sync
2. In the [CloudKit console](https://icloud.developer.apple.com), container
   `iCloud.com.neonpixel.pocketchef`, Development → Schema → Record Types, check that these have
   all their fields (SwiftData prefixes them `CD_`):

   | Record type | Fields |
   |---|---|
   | `CD_RecipeModel` | id, title, steps, equipment, isTypedSource, sourceURL, ingredients, tags, photos |
   | `CD_IngredientLineModel` | id, rawText, amount, unit, ingredientName, position, recipe |
   | `CD_TagModel` | id, name, isPreset, recipes |
   | `CD_RecipePhotoModel` | id, position, imageData, thumbnailData, recipe |

   Relationships and large data may show as differently named fields (for example `_ckAsset`), but
   each property needs one.
3. **Deploy Schema Changes…** to production, and check that the production record types match.

`DensityEntryModel` isn't listed: it's a local cache and never syncs.

**Density API.** `https://<api-hostname>/health` returns 200 (`api/docs/deploy.md`), and the host
and read key in Xcode Cloud's Release workflow are the production ones.

**App Store Connect.** For both iOS and macOS:
- App Privacy published ("Data Not Collected", `app-store-connect.md`); check it, `PRIVACY.md` and
  the privacy manifest against the code, as that doc asks before each release.
- The content rights answer given (still open in `app-store-connect.md`) and the age rating done.
- Screenshots in every language (`screenshots.md`), and the listing text from
  `app-store-listing.md`, after the native-speaker check.

**Version.** `MARKETING_VERSION` set to the release version, then tag (`release.md`).

## Stage 1: internal testing

The Release workflow puts both builds in TestFlight for the internal group. Install them from the
TestFlight app on an iPhone, an iPad and a Mac, signed in to the same Apple Account. Run every check
on each device unless it names one.

**First launch**
- The launch screen shows without a flash of another colour, then the welcome guide.
- The guide's pages read correctly; Settings → Show Welcome Guide opens it again.

**Adding recipes**
- **Type It** and **Paste a Link** on a device with Apple Intelligence: each fills the review
  screen, and nothing saves before Save. Try a link from a large recipe site.
- On a device without Apple Intelligence (or with it off): both explain that AI capture isn't
  available, and the form still works.
- **Enter Manually**: a recipe with ingredients, equipment, steps and tags saves and reopens
  unchanged, with the ingredient order kept.

**Cooking from a recipe**
- **Weight** shows grams for an English recipe ("2 cups flour"). This proves the build reaches the
  production density API; Settings → Ingredient Densities shows a recent update.
- Photos: add from the library on all three, take one with the camera on iPhone and iPad, set a
  cover, reorder, delete.
- Tags: preset and custom tags, filtering the list by tag.
- On iPad and Mac, the detail screen shows two columns in a wide window and one in a narrow one.

**iCloud (production)**
- Turn on iCloud in Settings on the iPhone and the Mac. Existing local recipes merge up, and each
  device shows the other's recipes, photos included.
- **The 4.1 check:** with the Mac app open and in front, edit a recipe on the iPhone. The edit must
  appear on the Mac within about a minute, without clicking the window. When it does, tick 4.1 in
  PLAN.md. If it doesn't, the push isn't arriving: compare with the development behaviour in the
  4.1 note before blaming the app.
- Delete a recipe on one device; it disappears on the other.
- Switch one device back to Local: its recipes stay, and later edits there don't sync.

**Languages.** Set a device to Spanish, French, German and Dutch in turn: the UI, preset tags and
guide are translated, with no English left over and nothing cut off.

**Gate:** every check passes on the build that will be submitted.

## Stage 2: external beta

1. TestFlight → External Testing: add a group and the build. The first build needs Beta App
   Review, so fill in Test Information: what to test (the capture paths, Weight, iCloud), a
   feedback email, and that no sign-in is needed. iOS and macOS are reviewed separately.
2. Invite testers, ideally with different devices, including some without Apple Intelligence and
   some writing recipes in Spanish, French, German or Dutch.
3. Run the beta for about a week. Each day, check TestFlight feedback and crashes (App Store
   Connect → TestFlight → Crashes, or Xcode → Organizer → Crashes).

**Gate:** no crash or data loss left open, and the feedback has nothing that blocks release.

## Stage 3: App Review

For each platform (iOS covers iPadOS), in the version's page:
1. Select the tested build.
2. **App Review Information:** no sign-in. In the notes, explain that Type It and Paste a Link use
   Apple Intelligence on the device, so a device without it only offers Enter Manually, and that
   iCloud sync is optional and off by default.
3. **Version Release:** *Manually release this version*, so all three platforms can go live
   together.
4. Submit for Review.

If App Review rejects a build, answer in Resolution Center. A metadata fix needs no new build; a code
fix goes through `release.md` and Stage 1 again.

**Gate:** both versions approved ("Pending Developer Release").

## Stage 4: release

1. Release both versions in App Store Connect on the same day.
2. Once they're live (this can take a few hours), install from the App Store on an iPhone, an iPad
   and a Mac (not over the TestFlight build), and run a short check: launch, add a recipe, Weight,
   iCloud sync between two devices.
3. Check the store pages in each language: name, subtitle, screenshots, description.
4. For the next few days, check crashes and ratings daily.

Tick 12.4 in PLAN.md once v1 is live on all three platforms.

For later releases, the CloudKit schema is already deployed: only a model change needs Stage 0's
schema steps again, and then only new fields (PLAN 4.1).
