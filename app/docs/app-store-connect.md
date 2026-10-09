# App Store Connect

What to enter in App Store Connect for Pocket Chef (PLAN 12.1), and why each answer is true. The
app record (bundle ID `com.neonpixel.pocketchef`) already exists: the `v0.1.0` build reached
TestFlight on iOS and macOS (12.3). iOS and macOS share it, so the record must list both
platforms (App Information → add macOS if it's missing); iPadOS comes with iOS.

## App Privacy

Under **App Privacy**:

| Field | Value |
|---|---|
| Privacy Policy URL | `https://github.com/neonpixel-software/pocket-chef/blob/main/PRIVACY.md` |
| Do you or your third-party partners collect data from this app? | **No, we do not collect data from this app** |

Then **Publish**. The label then reads "Data Not Collected", which covers every platform of the
record. Apple checks it during App Review, so it's verified with the first submission (12.4).

The privacy policy URL is also required for the macOS platform: set it once under App Privacy,
not per platform.

### Why "Data Not Collected" is true

Apple counts data as collected when it leaves the device and the developer (or a partner) can
read it for longer than it takes to answer the request. Pocket Chef sends nothing of that kind:

| What leaves the device | Where it goes | Why it isn't collected |
|---|---|---|
| Recipes, tags, photos (only with iCloud sync on) | The user's private CloudKit database | Only the user can read it; NeonPixel can't. |
| A request for a pasted recipe link | The recipe's own website | Goes straight to that site, never through NeonPixel. |
| `GET /density-entries` with the read key | Pocket Chef's density API | Carries nothing about the user. nginx keeps no access log (`api/docs/deploy.md` §6), the API logs no requests, and the rate limiter holds the address in memory for one 60-second window. |

There are no third-party SDKs in the app: its only package, ViewInspector, is linked into the
unit tests and not shipped. Recipe capture runs on the device with Apple Intelligence.

The app's privacy manifest (`Sources/PocketChef/Resources/PrivacyInfo.xcprivacy`) says the same:
no tracking, no collected data types. It also declares the one required-reason API the app's own
code uses, `UserDefaults`, with reason `CA92.1` (read and written by the app itself only).

Before each release, check the About page's "No Tracking" list, `PRIVACY.md`, the label and the
manifest against the code (see "No tracking" in
`docs/plans/2026-10-08-welcome-guide-and-about-design.md`). Anything that changes what leaves
the device, such as a new SDK, crash reporting, or logging on the server, changes them all.

## App Information

| Field | Value |
|---|---|
| Name | Pocket Chef |
| Primary category | Food & Drink (matches `LSApplicationCategoryType` in `project.yml`) |
| Content rights | Open question for the owner: the app fetches recipe websites the user links to and keeps the recipe text they review. Apple asks whether the app "contains, shows, or accesses third-party content"; answer **Yes** with "I have the necessary rights" only if that's agreed, otherwise **No** on the grounds that the user, not the app, brings the content. |
| Age rating | Answer **None** or **No** to every question, which gives 4+. "Unrestricted web access" is **No**: the app only fetches a page to turn it into a recipe and never shows it. |

## Version information (per platform)

| Field | Value |
|---|---|
| Support URL | `https://github.com/neonpixel-software/pocket-chef/issues` |
| Marketing URL | `https://github.com/neonpixel-software/pocket-chef` (optional) |
| Copyright | `2026 NeonPixel` |

Screenshots, the description and keywords come with 12.2.

## Export compliance

Nothing to answer: `project.yml` sets `ITSAppUsesNonExemptEncryption = NO`, since the app only
uses HTTPS (`docs/release.md`).
