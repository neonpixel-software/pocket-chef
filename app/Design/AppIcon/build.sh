#!/bin/zsh
# Regenerates the app icon's layer PNGs from make-icon-layers.swift, then renders previews of
# every appearance (light, dark, tinted, clear; iOS and macOS) with Icon Composer's ictool.
#
# Usage: app/Design/AppIcon/build.sh [preview directory]   (default: a new temporary directory)
set -euo pipefail

here=${0:A:h}
icon=${here:h:h}/Sources/RecipeRaccoon/Resources/AppIcon.icon
previews=${1:-$(mktemp -d)}
ictool="$(xcode-select -p)/../Applications/Icon Composer.app/Contents/Executables/ictool"
# :a resolves the ".." so the messages show plain paths.
ictool=${ictool:a}
if [[ ! -x $ictool ]]; then
  echo "Icon Composer's ictool isn't at $ictool." >&2
  echo "It ships inside Xcode 26 or later; point xcode-select at that Xcode (sudo xcode-select -s /path/to/Xcode.app)." >&2
  exit 1
fi

swift "$here/make-icon-layers.swift" "$icon/Assets"

mkdir -p "$previews"
for rendition in Default Dark TintedLight TintedDark ClearLight ClearDark; do
  "$ictool" "$icon" --export-image --output-file "$previews/iOS-$rendition.png" \
    --platform iOS --rendition "$rendition" --width 1024 --height 1024 --scale 1 >/dev/null
done
for rendition in Default Dark; do
  "$ictool" "$icon" --export-image --output-file "$previews/macOS-$rendition.png" \
    --platform macOS --rendition "$rendition" --width 1024 --height 1024 --scale 1 >/dev/null
done

# The welcome guide's first page shows the icon at 96 pt (WelcomeGuidePageView): 192 px at 2×
# and 288 px at 3×. macOS asset catalogs drop 3× images, so the 2× ones are needed on the Mac.
welcome=${icon:h}/Assets.xcassets/WelcomeAppIcon.imageset
for scale in 2 3; do
  for rendition in Default Dark; do
    appearance=${${rendition:l}/default/light}
    "$ictool" "$icon" --export-image --output-file "$welcome/welcome-app-icon-$appearance@${scale}x.png" \
      --platform iOS --rendition "$rendition" --width $((96 * scale)) --height $((96 * scale)) --scale 1 >/dev/null
  done
done

echo "Layers written to $icon/Assets, welcome guide icon to $welcome; previews in $previews"
