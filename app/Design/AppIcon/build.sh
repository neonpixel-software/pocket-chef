#!/bin/zsh
# Regenerates the app icon's layer PNGs from make-icon-layers.swift, then renders previews of
# every appearance (light, dark, tinted, clear; iOS and macOS) with Icon Composer's ictool.
#
# Usage: app/Design/AppIcon/build.sh [preview directory]   (default: a new temporary directory)
set -euo pipefail

here=${0:A:h}
icon="$here/../../Sources/PocketChef/Resources/AppIcon.icon"
previews=${1:-$(mktemp -d)}
ictool="$(xcode-select -p)/../Applications/Icon Composer.app/Contents/Executables/ictool"
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
echo "Layers written to $icon/Assets; previews in $previews"
