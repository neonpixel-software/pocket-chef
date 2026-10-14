# App Store screenshots

PLAN.md 12.2. The screenshots are real captures of the app, taken by a UI test
(`Tests/RecipeRaccoonUITests/AppStoreScreenshotsUITests.swift`) in a fixed starting state,
`UITestScenario.screenshots`. Take them again after any visible UI change.

## Taking them

```sh
app/Scripts/take-screenshots.sh                  # everything: iPhone, iPad and Mac, five languages
app/Scripts/take-screenshots.sh -p iphone -l en  # one platform, one language
```

They land in `app/build/screenshots/<platform>/<language>/` (gitignored), named in upload order.
The whole set takes about 20 minutes. A failed run leaves `app/build/screenshots/failed.xcresult`;
open it in Xcode to see the failure, the UI hierarchy and a screen recording.

- **iPhone and iPad** run on simulators the script creates on first use, "Pocket Chef Screenshots
  iPhone" (iPhone 17) and "… iPad" (iPad Pro 13-inch). They're new, so no Apple Account, recipes or
  notifications show. The script sets them to US English (a 12-hour clock) and Apple's usual status
  bar: 9:41, full signal and battery. It also sets iPad multitasking to Full Screen Apps; in the
  default Windowed Apps mode a resize handle shows in the bottom-right corner. It does this with
  two private SpringBoard defaults (what Settings → Multitasking & Gestures writes), which a future
  iPadOS could ignore without any error, so check the bottom-right corners of the iPad shots.
- **Mac** is the app's window on this Mac, moved to the main screen, in light mode. The window is
  1440 × 900 pt, so a Retina main screen gives 2880 × 1800 and a 1× screen 1440 × 900. App Store
  Connect takes both, but use a Retina screen for the final set: it's sharper. Don't touch the
  mouse or keyboard while the Mac set runs; the test clicks and types in the window.

## What they show

| # | Screen | Notes |
|---|--------|-------|
| 1 | Recipe list | Six recipes with photos and tags |
| 2 | Recipe detail | Fluffy Pancakes: photo, tags, ingredients as written |
| 3 | Weight view | Chocolate Chip Cookies in grams. English only (see below) |
| 4 | Tag filter | The list filtered by Dessert |
| 5 | Paste a Link | AI capture from a recipe link, with a link typed in |

The recipes are in `Data/DevSupport/ScreenshotRecipes.swift`, in all five languages. The weight
view is only in the English set: the density table names ingredients in English, so a recipe
written in Spanish, French, German or Dutch has no weights to show, and a screenshot showing them
would promise something the app doesn't do. The other languages have four screenshots.

AI capture isn't available on simulators, so the scenario counts it as available
(`treatsCaptureAsAvailable`). Screenshot 5 shows the capture screen only, never a capture result.

## Uploading

App Store Connect → the app → the version → each language → Previews and Screenshots:

| App Store Connect slot | Folder | Size |
|---|---|---|
| iPhone, 6.3" display (Dynamic Island, medium) | `iphone/<language>` | 1206 × 2622 |
| iPad, 13" display | `ipad/<language>` | 2064 × 2752 |
| Mac | `mac/<language>` | 2880 × 1800 (or 1440 × 900) |

Smaller iPhones and iPads use scaled copies of these. Apple's current list:
https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications

## Photo credits

The recipe photos are from Wikimedia Commons and free to use for any purpose, with no attribution
required (CC0 or public domain). They're scaled to 1400 px, live in
`Data/DevSupport/ScreenshotPhotos/` and ship in Debug builds only (`EXCLUDED_SOURCE_FILE_NAMES` in
`Config/RecipeRaccoon.xcconfig`).

| Photo | Author | License | Source |
|---|---|---|---|
| Pancakes | Mae Mu (Foodiesfeed) | CC0 | [Foodiesfeed.com pouring-honey-on-pancakes-with-walnuts.jpg](https://commons.wikimedia.org/wiki/File:Foodiesfeed.com_pouring-honey-on-pancakes-with-walnuts.jpg) |
| Chocolate chip cookies | Mshuang2 | CC0 | [Chocolate chip cookies on cutting board.jpg](https://commons.wikimedia.org/wiki/File:Chocolate_chip_cookies_on_cutting_board.jpg) |
| Shakshuka | Andy Li | CC0 | [Shakshuka - Black Mocha 2025-03-13.jpg](https://commons.wikimedia.org/wiki/File:Shakshuka_-_Black_Mocha_2025-03-13.jpg) |
| Spaghetti | unknown | Public domain | [Spaghetti-prepared.jpg](https://commons.wikimedia.org/wiki/File:Spaghetti-prepared.jpg) |
| Greek salad | Gesalbte | Public domain | [Greek salad from supermarket.JPG](https://commons.wikimedia.org/wiki/File:Greek_salad_from_supermarket.JPG) |
| Chocolate banana bread | Andy Li | CC0 | [Dark chocolate & banana loaf - Bread & Milk 2024-06-27.jpg](https://commons.wikimedia.org/wiki/File:Dark_chocolate_%26_banana_loaf_-_Bread_%26_Milk_2024-06-27.jpg) |
