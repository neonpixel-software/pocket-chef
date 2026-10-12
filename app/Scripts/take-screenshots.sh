#!/bin/zsh
# Takes the App Store screenshots (PLAN.md 12.2; app/docs/screenshots.md) by running
# AppStoreScreenshotsUITests in UITestScenario.screenshots, then exports them as PNGs:
#
#   <output>/<platform>/<language>/<n>-<screen>.png
#
# iPhone 17 (1206 × 2622) and iPad Pro 13-inch (2064 × 2752) run on simulators the script creates
# for this ("Pocket Chef Screenshots …"), so no Apple Account or old data shows; the Mac
# screenshots are the app's window on this Mac (2880 × 1800 on a Retina screen).
#
# Usage: app/Scripts/take-screenshots.sh [-o output] [-p "iphone ipad mac"] [-l "en es fr de nl"]
set -euo pipefail

app=${0:A:h:h}
output="$app/build/screenshots"
platforms=(iphone ipad mac)
languages=(en es fr de nl)
while getopts "o:p:l:" option; do
  case $option in
    o) output=${OPTARG:A} ;;
    p) platforms=(${=OPTARG}) ;;
    l) languages=(${=OPTARG}) ;;
    *) echo "Usage: $0 [-o output] [-p platforms] [-l languages]" >&2; exit 2 ;;
  esac
done

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
runtime=$(xcrun simctl list runtimes iOS -j | python3 -I -c 'import json, sys; print([r["identifier"] for r in json.load(sys.stdin)["runtimes"] if r["isAvailable"]][-1])')

# The UDID of the named screenshot simulator, created on first use, booted, set to US English
# (a 12-hour clock in the status bar) and showing Apple's usual status bar.
simulator() {
  local name="Pocket Chef Screenshots $1" type=$2 udid
  udid=$(xcrun simctl list devices -j | python3 -I -c "import json, sys
for devices in json.load(sys.stdin)['devices'].values():
    for d in devices:
        if d['name'] == '$name' and d['isAvailable']: print(d['udid']); break" | head -1)
  if [[ -z $udid ]]; then
    udid=$(xcrun simctl create "$name" "$type" "$runtime")
  fi
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
  if [[ $(xcrun simctl spawn "$udid" defaults read -g AppleLocale 2>/dev/null) != en_US ]]; then
    xcrun simctl spawn "$udid" defaults write -g AppleLocale en_US
    xcrun simctl spawn "$udid" defaults write -g AppleLanguages -array en
    xcrun simctl shutdown "$udid"
    xcrun simctl boot "$udid"
    xcrun simctl bootstatus "$udid" -b >/dev/null
  fi
  xcrun simctl status_bar "$udid" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState discharging --batteryLevel 100
  echo "$udid"
}

cd "$app"
xcodegen generate --quiet

for platform in $platforms; do
  case $platform in
    iphone) scheme=PocketChef-iOS; destination="id=$(simulator iPhone com.apple.CoreSimulator.SimDeviceType.iPhone-17)" ;;
    ipad) scheme=PocketChef-iOS; destination="id=$(simulator iPad com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB)" ;;
    mac) scheme=PocketChef-macOS; destination="platform=macOS" ;;
    *) echo "Unknown platform $platform (iphone, ipad, mac)" >&2; exit 2 ;;
  esac
  for language in $languages; do
    echo "Taking the $platform screenshots in $language…"
    result="$work/$platform-$language.xcresult"
    TEST_RUNNER_POCKETCHEF_SCREENSHOTS=1 TEST_RUNNER_POCKETCHEF_SCREENSHOT_LANGUAGE=$language \
      xcodebuild test -project PocketChef.xcodeproj -scheme "$scheme" -destination "$destination" \
      -derivedDataPath "$work/DerivedData" -only-testing:"$scheme"UITests/AppStoreScreenshotsUITests \
      -resultBundlePath "$result" -quiet >"$work/$platform-$language.log" 2>&1 ||
      { tail -40 "$work/$platform-$language.log" >&2; mkdir -p "$output"; rm -rf "$output/failed.xcresult"; mv "$result" "$output/failed.xcresult"
        echo "The $platform screenshots in $language failed; open $output/failed.xcresult for details" >&2; exit 1; }
    xcrun xcresulttool export attachments --path "$result" --output-path "$work/$platform-$language" >/dev/null
    rm -rf "$output/$platform/$language"
    mkdir -p "$output/$platform/$language"
    swift "$app/Scripts/finish-screenshots.swift" "$platform" "$work/$platform-$language" "$output/$platform/$language"
  done
done
echo "Screenshots in $output"
