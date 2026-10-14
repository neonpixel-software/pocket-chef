# App icon

The icon is a raccoon in a chef's hat, in the app's palette (`PCColor`): an ink raccoon with a
white hat on pink for light mode, a cream raccoon with a pink hat on ink for dark mode.

It ships as an Icon Composer file, `app/Sources/RecipeRaccoon/Resources/AppIcon.icon`, so iOS,
iPadOS and macOS 26 draw it with Liquid Glass and generate the tinted and clear looks.

- `icon.json` sets the background (pink, or ink in dark mode), picks each layer's image per
  appearance, and hides the dot texture in dark mode. Tinted and clear modes use the cream
  raccoon and the white hat, because tinting follows brightness and an ink raccoon would vanish.
  Only the `tinted` entries say so: clear has no appearance of its own in `icon.json` (ictool
  rejects `"clear"` as unreadable) and uses the tinted images. Without `tinted` entries, the
  fallback depends on the Icon Composer version: Xcode 26's `ictool` falls back to the `dark`
  images (the same cream raccoon here), Xcode 27's goes straight to the default ink raccoon,
  which clear mode draws as a faint glass outline. The explicit `tinted` entries give the same
  icon with either.
- `Assets/` holds the layers as 1024 × 1024 PNGs: `head-*`, `hat-*` and `dots`. Don't edit them
  by hand; they're generated.

## Changing the icon

The drawing lives in `make-icon-layers.swift` (shapes on a 1024 canvas). After editing it, run:

```sh
app/Design/AppIcon/build.sh [preview directory]
```

It rewrites the layer PNGs and renders previews of every appearance with Icon Composer's `ictool`
(iOS light, dark, tinted, clear; macOS light and dark). It also re-renders the icon the welcome
guide shows on its first page (`Assets.xcassets/WelcomeAppIcon.imageset`, light and dark, at 1×,
2× and 3×), so commit those with the layers. Check the previews before committing.
You can also open `AppIcon.icon` in Icon Composer (in Xcode's Developer Tools menu).

Each layer PNG has two near-invisible pixels in opposite corners. Icon Composer crops a layer to
its visible pixels and centres it, so without them the hat and head would move.
