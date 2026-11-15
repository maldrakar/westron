#!/usr/bin/env bash
# A screenshot of a catalog entry on the iOS simulator or macOS: the agent's "eyes" and the review surface.
#
#   tools/apple/catalog-screenshot.sh <ios|macos> [--entry ID] [--appearance light|dark] [--contrast standard|high]
#                                     [--dynamic-type SIZE] [--device "iPhone 17"] [--out FILE.png]
#
# Builds the catalog (incrementally), runs the CatalogScreenshotTests UI test and prints the absolute path to the PNG.
# By default the PNG goes to .build/screenshots/<platform>-<id>[-<theme>][-hc][-<size>].png, the xcodebuild log to
# .build/logs/.
# macOS: Automation Mode must be enabled once per machine (see platforms/apple/README.md).
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
# shellcheck source=tools/apple/xcode-env.sh
source tools/apple/xcode-env.sh

usage() { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

platform="${1:-}"
[ "$platform" = ios ] || [ "$platform" = macos ] || usage
shift
entry=environment appearance="" contrast="" dynamic_type="" device="${WESTRON_SIM_DEVICE:-iPhone 17}" out=""
while [ $# -gt 0 ]; do
  case "$1" in
    --entry) entry="$2"; shift 2 ;;
    --appearance) appearance="$2"; shift 2 ;;
    --contrast) contrast="$2"; shift 2 ;;
    --dynamic-type) dynamic_type="$2"; shift 2 ;;
    --device) device="$2"; shift 2 ;;
    --out) out="$2"; shift 2 ;;
    *) usage ;;
  esac
done

hc=""
[ "$contrast" = high ] && hc="-hc"
name="$platform-$entry${appearance:+-$appearance}$hc${dynamic_type:+-$dynamic_type}"
out="${out:-.build/screenshots/$name.png}"
case "$out" in /*) ;; *) out="$root/$out" ;; esac
mkdir -p "$(dirname "$out")" .build/logs
rm -f "$out"
log=".build/logs/catalog-$name.log"

if [ "$platform" = ios ]; then
  # The newest iOS runtime with this device, no newer than the SDK of the current Xcode.
  sdk_version="$(xcrun --sdk iphonesimulator --show-sdk-version)"
  # jq ships with macOS. Versions become [major, minor, patch] and compare as arrays.
  udid="$(xcrun simctl list devices available -j | jq -r --arg device "$device" --arg sdk "$sdk_version" '
    def version: split(".") | map(tonumber) | (. + [0, 0, 0])[0:3];
    ($sdk | version) as $max
    | [.devices | to_entries[]
        | (.key | capture("SimRuntime\\.iOS-(?<v>[0-9]+(-[0-9]+)*)$").v | gsub("-"; ".") | version) as $v
        | .value[] | select(.name == $device) | {udid, v: $v}]
    | (map(select(.v <= $max))) as $fits
    | (if ($fits | length) > 0 then $fits else . end)
    | sort_by(.v) | last | .udid // empty
  ')"
  if [ -z "$udid" ]; then
    echo "catalog-screenshot: no simulator \"$device\"; list the available ones: xcrun simctl list devices available" >&2
    exit 1
  fi
  xcrun simctl bootstatus "$udid" -b > /dev/null
  # The same status bar on every screenshot.
  xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 \
    --wifiBars 3 --cellularMode active --cellularBars 4 --dataNetwork wifi
  destination="id=$udid"
else
  destination="platform=macOS,arch=$(uname -m)"
fi

xcodebuild_args=(-project platforms/apple/Catalog/Catalog.xcodeproj -scheme Catalog -destination "$destination"
  -derivedDataPath .build/xcode/catalog)

if ! xcodebuild "${xcodebuild_args[@]}" build-for-testing > "$log" 2>&1; then
  grep -E "error:|BUILD FAILED" "$log" | head -20 >&2 || true
  echo "catalog-screenshot: build failed, log: $log" >&2
  exit 1
fi

screenshot_failed() {
  grep -E ": error: |Underlying Error|automation mode" "$log" | grep -v "\[MT\]" | head -20 >&2 || true
  echo "catalog-screenshot: no screenshot captured, log: $log" >&2
  exit 1
}

export TEST_RUNNER_WESTRON_ENTRY="$entry"
[ -n "$appearance" ] && export TEST_RUNNER_WESTRON_APPEARANCE="$appearance"
[ -n "$contrast" ] && export TEST_RUNNER_WESTRON_CONTRAST="$contrast"
[ -n "$dynamic_type" ] && export TEST_RUNNER_WESTRON_DYNAMIC_TYPE="$dynamic_type"

# The runner does not write the file itself (on macOS it is sandboxed): the PNG is an attachment in the test result.
results=".build/xcode/results/$name.xcresult"
attachments=".build/xcode/results/$name-attachments"
rm -rf "$results" "$attachments"
mkdir -p .build/xcode/results

xcodebuild "${xcodebuild_args[@]}" test-without-building -resultBundlePath "$results" \
  -only-testing:CatalogUITests/CatalogScreenshotTests/testScreenshot >> "$log" 2>&1 || screenshot_failed
xcrun xcresulttool export attachments --path "$results" --output-path "$attachments" \
  --filter "westron-screenshot*" >> "$log" 2>&1 || screenshot_failed
png="$(find "$attachments" -name '*.png' | head -1)"
[ -n "$png" ] || screenshot_failed
mv "$png" "$out"

echo "$out"
