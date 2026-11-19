#!/usr/bin/env bash
# The snapshot matrix (#24): every combination each component's contract declares, in the four themes and, on iOS,
# at the smallest and the largest text size, with the catalog's supplementary sheets (#72), for review.
#
#   tools/apple/snapshot-matrix.sh <ios|macos> [--component ID[,ID…]]… [--device "iPhone 17"] [--out DIR]
#   tools/apple/snapshot-matrix.sh compare DIR_A DIR_B [--out DIR]
#   tools/apple/snapshot-matrix.sh merge [--expect ID,ID…] OUT DIR...
#
# Capture: builds the catalog (incrementally), then runs the SnapshotMatrixTests UI test in one `xcodebuild test`
# invocation, which walks every sheet of every matrix (generated from the contracts into WestronCatalog/Generated/)
# and of its supplements in light, dark, light-hc and dark-hc at the default text size, and on iOS in light at xSmall
# and accessibility5 (macOS has no Dynamic Type); with --component, of the components it names only (repeated or
# comma-separated, still one run). The PNGs, named <component>.<sheet>.<theme>.png and
# <component>.<sheet>[_part-<n>-of-<count>].light.<text size>.png, the manifest matrix.json and the review page
# index.html go to DIR, by default .build/snapshot-matrix/<platform>/; the script prints the path of index.html and
# fails when an expected image is missing or a sheet failed its checks. Log: .build/logs/.
# The sheets are laid out for the default device, iPhone 17 in portrait: at accessibility5 a part of one column and six
# rows just fits it, so another --device, a shorter one above all, may fail the check that every cell is inside the
# picture there.
# Compare: compares two capture directories image by image and writes a report page, by default to
# .build/snapshot-matrix/compare/; prints its path; exits 0 when every image is the same and 1 when one differs.
# Between two iOS captures it ignores the home indicator, which the system draws or not from launch to launch, where
# the differing pixels fit its footprint at the bottom of the screen, and shows those images apart
# (platforms/apple/README.md, "Snapshot matrix"). Only captures from the same environment compare (decisions/0008).
# macOS needs Automation Mode (platforms/apple/README.md) and the screen to itself.
# Merge: puts captures of one platform taken apart (--component, one CI job each) into OUT as one: their PNGs, one
# manifest and one review page; prints its path. With --expect, the components go in that order and the page names
# at its top every expected one that no capture holds. Exits 1 when a component or a capture's manifest is missing or
# the page finds a problem.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
# shellcheck source=tools/apple/xcode-env.sh
source tools/apple/xcode-env.sh

usage() { sed -n '2,/^set /{/^#/p;}' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

absolute() { case "$1" in /*) echo "$1" ;; *) echo "$root/$1" ;; esac; }

# The page builder and the image comparison: a Swift file compiled once, again when it changes.
pages() {
  local source=tools/apple/snapshot-pages.swift binary=.build/tools/snapshot-pages
  if [ ! -x "$binary" ] || [ "$source" -nt "$binary" ]; then
    mkdir -p .build/tools
    xcrun --sdk macosx swiftc -O -o "$binary" "$source" >&2
  fi
  "$binary" "$@"
}

if [ "${1:-}" = merge ]; then
  shift
  expect=""
  if [ "${1:-}" = --expect ]; then
    expect="$2"
    shift 2
  fi
  [ $# -ge 2 ] || usage
  out="$(absolute "$1")"
  shift
  mkdir -p "$out"
  rm -f -- "$out/matrix.json" "$out/index.html"
  manifests=() status=0 lost=()
  for capture in "$@"; do
    capture="$(absolute "$capture")"
    if [ ! -f "$capture/matrix.json" ]; then
      echo "snapshot-matrix: merge: no manifest in $capture; its components are missing from the page" >&2
      lost+=("$capture")
      status=1
      continue
    fi
    manifests+=("$capture/matrix.json")
    find "$capture" -maxdepth 1 -name '*.png' -exec cp -- {} "$out/" \;
  done
  [ ${#manifests[@]} -gt 0 ] || { echo "snapshot-matrix: merge: no manifest to merge" >&2; exit 1; }
  if [ "$(jq -s 'map(.platform) | unique | length' "${manifests[@]}")" != 1 ]; then
    echo "snapshot-matrix: merge: the captures are of different platforms" >&2
    exit 2
  fi
  # The first manifest's environment, the components of all, and a scale from a capture that took an image (a capture
  # that failed before its first image says 0). With --expect, the components go in its order, and every expected one
  # that no manifest holds is named in `missing`, which the page shows at its top; without it, a capture with no
  # manifest is named by its directory.
  jq -s --arg expect "$expect" --arg lost "$(printf '%s\n' ${lost[@]+"${lost[@]}"})" '
    ($expect | split(",") | map(select(. != ""))) as $expected
    | (map(.components) | add) as $components
    | ($components | map(.component)) as $present
    | .[0] + {
        scale: (map(.scale) | max),
        components: (if ($expected | length) > 0
          then $components | sort_by(.component as $id | $expected | index($id) // length)
          else $components end),
        missing: (if ($expected | length) > 0
          then $expected - $present
          else $lost | split("\n") | map(select(. != "") | "the capture in " + .) end)
      }' "${manifests[@]}" > "$out/matrix.json"
  if [ "$(jq '.missing | length' "$out/matrix.json")" != 0 ]; then
    echo "snapshot-matrix: merge: missing: $(jq -r '.missing | join(", ")' "$out/matrix.json")" >&2
    status=1
  fi
  pages index "$out" || status=1
  echo "$out/index.html"
  exit "$status"
fi

if [ "${1:-}" = compare ]; then
  shift
  [ $# -ge 2 ] || usage
  before="$(absolute "$1")" after="$(absolute "$2")"
  shift 2
  out=".build/snapshot-matrix/compare"
  while [ $# -gt 0 ]; do
    case "$1" in
      --out) out="$2"; shift 2 ;;
      *) usage ;;
    esac
  done
  out="$(absolute "$out")"
  mkdir -p "$out"
  status=0
  pages compare "$before" "$after" "$out" || status=$?
  [ "$status" -le 1 ] || exit "$status"
  echo "$out/index.html"
  exit "$status"
fi

platform="${1:-}"
[ "$platform" = ios ] || [ "$platform" = macos ] || usage
shift
component="" device="${WESTRON_SIM_DEVICE:-iPhone 17}" out=""
while [ $# -gt 0 ]; do
  case "$1" in
    # Repeated or comma-separated: one list, in one test run.
    --component) component="${component:+$component,}$2"; shift 2 ;;
    --device) device="$2"; shift 2 ;;
    --out) out="$2"; shift 2 ;;
    *) usage ;;
  esac
done
out="$(absolute "${out:-.build/snapshot-matrix/$platform}")"
# The log and the result bundle name the components, joined with "+": snapshot-matrix-ios-rule+surface.log.
name="snapshot-matrix-$platform${component:+-${component//,/+}}"
log=".build/logs/$name.log"
mkdir -p "$out" .build/logs .build/xcode/results
# Only a capture's own files are removed, so --out can name a directory that holds other files: the images the previous
# manifest names (in this format, or the earlier one with a file name per theme), any <component>.*.<capture>.png of a component
# in spec/components whose name ends in a capture's name (a capture that failed before its manifest), the manifest and
# the page. The capture names are ComponentMatrix.Capture's: the themes at the default text size, then light at the
# other text sizes.
captures=(light dark light-hc dark-hc light.xSmall light.accessibility5)
if [ -f "$out/matrix.json" ]; then
  { jq -r '(.. | objects | select(has("file")) | .file), (.components[]?.sheets[]?.images[]? | strings)' \
    "$out/matrix.json" 2> /dev/null || true; } | while read -r file; do
    case "$file" in */* | "") ;; *) rm -f -- "$out/$file" ;; esac
  done
fi
for contract in spec/components/*/; do
  id="$(basename "$contract")"
  for capture in "${captures[@]}"; do rm -f -- "$out/$id."*".$capture.png"; done
done
rm -f -- "$out/matrix.json" "$out/index.html"

udid=""
if [ "$platform" = ios ]; then
  # shellcheck source=tools/apple/simulator.sh
  source tools/apple/simulator.sh
  udid="$(westron_simulator_udid "$device")" || exit 1
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
  echo "snapshot-matrix: build failed, log: $log" >&2
  exit 1
fi

results=".build/xcode/results/$name.xcresult"
attachments=".build/xcode/results/$name-attachments"
rm -rf "$results" "$attachments"

export TEST_RUNNER_WESTRON_MATRIX=1
[ -n "$component" ] && export TEST_RUNNER_WESTRON_MATRIX_COMPONENT="$component"

# One test invocation for the whole matrix. Without -collect-test-diagnostics never, a failed run waits minutes for a
# sysdiagnose of the simulator. A failed test still exports what it captured, so the page shows what went wrong.
echo "== snapshot-matrix: $destination${component:+, $component}" >&2
test_status=0
xcodebuild "${xcodebuild_args[@]}" test-without-building -resultBundlePath "$results" \
  -collect-test-diagnostics never \
  -only-testing:CatalogUITests/SnapshotMatrixTests/testMatrix >> "$log" 2>&1 || test_status=$?
grep -E "^matrix: |: error: " "$log" | grep -v "\[MT\]" >&2 || true
if [ -n "$udid" ] && ! pgrep -f "xcodebuild.*-destination id=$udid" > /dev/null; then
  # After UI tests the simulator's testmanagerd has been seen to spin for hours (tools/apple/check.sh, a11y).
  xcrun simctl spawn "$udid" launchctl kill SIGKILL system/com.apple.testmanagerd > /dev/null 2>&1 || true
fi

if ! xcrun xcresulttool export attachments --path "$results" --output-path "$attachments" >> "$log" 2>&1; then
  echo "snapshot-matrix: no attachments in $results, log: $log" >&2
  exit 1
fi
# The export names each file by its own id; its manifest.json maps them to the names the test gave the attachments,
# which xcresulttool suggests as `<name without .png>_<n>_<UUID>.png`.
jq -r '.[].attachments[] | [.exportedFileName, .suggestedHumanReadableName] | @tsv' \
  "$attachments/manifest.json" | while IFS=$'\t' read -r file label; do
  case "$label" in
    westron-matrix-manifest*) target="matrix.json" ;;
    westron-matrix-*.png)
      target="$(sed -E 's/^westron-matrix-//; s/(\.png)?(_[0-9]+_[0-9A-Fa-f-]+)?\.png$//' <<< "$label").png" ;;
    *) continue ;;
  esac
  mv "$attachments/$file" "$out/$target"
done
rm -rf "$attachments"

if [ ! -f "$out/matrix.json" ]; then
  echo "snapshot-matrix: the test wrote no manifest (status $test_status), log: $log" >&2
  exit 1
fi
page_status=0
pages index "$out" || page_status=$?
echo "$out/index.html"
if [ "$test_status" -ne 0 ] || [ "$page_status" -ne 0 ]; then
  echo "snapshot-matrix: the capture failed (test status $test_status), log: $log, result: $results" >&2
  exit 1
fi
