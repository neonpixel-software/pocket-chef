# Phase 14: Welcome guide and About — design

Source: `PLAN.md` Phase 14 (added 2026-10-08, before the first release).

Goal: a new user learns what Pocket Chef does and what they can change in
Settings, once, without reading a manual. Anyone can find out why the app
exists, that it's open source and doesn't track them, and where to check the
code or report a problem.

## Scope decisions (user, 2026-10-08)

- **A welcome guide shown once.** It explains the app's features and its
  settings, and can be opened again from Settings.
- **An About page.** It covers the idea behind the app, that it's open source
  and doesn't track anyone, and links to the GitHub repository so people can
  check the code themselves or report an issue.

## Welcome guide

### When it shows

- On the first launch on a device, over the recipe list. A `UserDefaults` flag
  (`hasSeenWelcomeGuide`) records that it was shown. It's per device, not
  synced, so a second device shows the guide once too.
- An existing install has no flag yet, so current users see the guide once
  after updating. They also haven't seen the Settings it explains.
- It's marked as seen when it closes, whether through Skip, Get Started or a
  swipe down. Someone who closed it doesn't need it pushed again.
- **Settings → Show Welcome Guide** opens it again, on every platform. The Mac
  also gets it in the Help menu, replacing the default Help item, which
  searches for a help book the app doesn't have.
- UI test runs (`-UITestScenario`) never show it on their own, or it would
  cover the screen every test checks. A `welcomeGuide` scenario opens it for
  its own tests.

### Presentation

- **iPhone:** full screen.
- **iPad and Mac:** a sheet, about 560 × 520 pt. The size is fixed so it doesn't
  jump between pages; 520 pt fits the longest page (4) as a short list. A page
  whose text still doesn't fit, with large Dynamic Type or a long translation,
  scrolls inside the page rather than being cut off.
- One page at a time, in a paged horizontal scroll view like the photo gallery
  (13.3), with page dots. On the Mac there are arrow buttons and ← → as well.
- Skip at the top on every page but the last. The bottom button reads Next, and
  Get Started on the last page.
- Each page: an SF Symbol in a pink circle, a title in the display font and a
  short body (two to four sentences). No screenshots: they'd have to be redone
  for every UI change, in five languages.

### Pages

1. **Welcome to Pocket Chef.** A recipe box without the fluff: no ads, no life
   stories, just the recipe.
2. **Add a recipe.** Three ways, from the + button:
   - Type It: paste or type a recipe's text.
   - Paste a Link: a recipe web page.
   - Enter Manually.
   For the first two, Apple Intelligence reads the recipe on your device, and
   you always check it before it's saved. Where Apple Intelligence isn't
   available, this page only explains Enter Manually and says that the other
   two need Apple Intelligence. That's the same check the + menu already uses
   (`CheckCaptureAvailabilityUseCase`).
3. **Cook from it.** Photos, tags and the tag filter on the list. The As
   Written / Weight switch shows ingredients in grams.
4. **Make it yours (Settings).**
   - Storage: on this device, or synced with iCloud.
   - Cups and spoons: US or metric, for weight conversion.
   - Ingredient densities, which update daily.
   - Where Settings is: the gear on iPhone and iPad, Pocket Chef → Settings
     (⌘,) on the Mac.

### Architecture

- **Domain:** `WelcomeGuideStatus`, a protocol with `hasSeen` and
  `markSeen()`.
- **Data:** a `UserDefaults` implementation.
- **Presentation:** `WelcomeGuideViewModel` builds the pages, adapting page 2
  to capture availability, tracks the current page and marks the guide seen
  on close. `WelcomeGuideView` shows them. The page content is plain data
  (symbol, title, body), so a unit test can check it without a view.
- The list view model decides whether to show the guide at launch.

## About

### Where

- **iPhone and iPad:** Settings → About Pocket Chef, a row at the bottom of
  the Settings sheet that opens the About page.
- **Mac:** Pocket Chef → About Pocket Chef in the app menu opens it in its own
  window, replacing the standard About panel. That panel can only show the
  icon, the version and a credits file, and the links wouldn't fit there.

### Content

**The idea.** Recipe sites bury the recipe under ads, pop-ups and life
stories. Pocket Chef keeps just the recipe: type it, paste it or link it,
check it once, and cook from a clean page.

**Open source.** Pocket Chef is open source under the MIT license. Anyone can
read the code, check what the app does, and build it themselves.

**No tracking.** This has to stay literally true, and the online list has to
be complete, not a set of examples:
- No account, no ads, no analytics, no tracking.
- Your recipes stay on this device, or in your own iCloud if you turn on sync.
- Recipe capture runs on your device.
- The app only goes online to:
  - fetch the recipe from a link you paste (that website sees the visit, as it
    would in a browser);
  - sync your recipes through your own iCloud, if you turn it on;
  - download ingredient densities from Pocket Chef's server. The app sends it
    nothing about you or your recipes.

Checked against the code on 2026-10-08: the app's only network code is
`URLSessionWebPageFetcher` (links), `URLSessionDensityEntryRemoteSource`
(densities) and CloudKit (`RecipeStore` with iCloud on, and
`CloudKitAccountStatusProvider`). Its one `openURL` opens the system Settings.
The About links open in the browser, which the user starts.

**Links.** Both open in the browser:
- **View the Code on GitHub:** https://github.com/neonpixel-software/pocket-chef
- **Report an Issue:** https://github.com/neonpixel-software/pocket-chef/issues/new
  A footnote says that reporting needs a free GitHub account.

**Footer:** the version and build ("Version 0.1.0 (1)", read from the bundle)
and "Made by NeonPixel".

### Architecture

- An `AboutInfo` value holds the repository URL, the issues URL, the version
  and the build, so it can be tested without a view.
- The URLs live in one place, in code, not in the strings catalog: they're not
  translated, and a typo in one language mustn't break a link.

## Accessibility and localization

- Headings carry the `.isHeader` trait. Each guide page reads as one element,
  title then body. The page dots are hidden from VoiceOver, since each page
  says its position ("Page 2 of 4").
- All text is in the five languages (en, es, fr, de, nl), informal register.
  The About and guide texts are longer than earlier strings, so the drafts get
  a native-speaker review of their own: 14.1 opens a new issue for de, es, fr
  and nl, which 14.2 adds to. #65 only covers two capture-flow error strings in
  nl and es, so it isn't widened. Where the guide names capture-flow screens
  and buttons, it uses their existing translations.

## Testing

Unit tests:
- the seen flag: first launch shows the guide, closing it marks it seen,
  Settings opens it again;
- page 2 with and without capture availability;
- the About URLs and version string;
- the views, through ViewInspector: pages, buttons, link destinations;
- the translated strings.

UI tests:
- `welcomeGuide` opens it, Next moves on, and Get Started closes it, on iOS.
  As with the photos, a tap doesn't reach the app on the GitHub macOS runner,
  so the Mac gets a layout check only.
- A normal scenario launch doesn't show it.

The privacy text gets a manual read against the code before release: Phase
12.1's privacy labels and this page must say the same thing. That read repeats
the network check above, searching `Sources/` for every way out (`URLSession`,
`URLRequest`, CloudKit, web views, `openURL`, any URL string) and for any App
Transport Security exception in the Info.plists. It passes only if every hit
is on the About page's list.

## Delivery

Two PRs, each shippable on its own:

1. **14.1 Welcome guide:** the seen flag, the guide, the Settings entry, the
   Mac Help menu item, strings, tests.
2. **14.2 About:** the About page, the Settings row, the Mac app menu item,
   strings, tests.
