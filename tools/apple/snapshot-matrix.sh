#!/usr/bin/env bash
# The snapshot matrix (#24, #92): every combination each component's contract declares, in the four themes and, on
# iOS, at the smallest and the largest text size, with the catalog's supplementary sheets (#72), rendered in-process
# and compared with the references in platforms/apple/Snapshots/.
#
#   tools/apple/snapshot-matrix.sh <ios|macos> [--component ID[,ID…]]… [--device "iPhone 17"] [--out DIR]
#   tools/apple/snapshot-matrix.sh compare DIR_A DIR_B [--out DIR] [--tolerance N]
#   tools/apple/snapshot-matrix.sh check <ios|macos> [--from DIR] [--device "iPhone 17"] [--out DIR] [--tolerance N]
#   tools/apple/snapshot-matrix.sh record <ios|macos> [--from DIR] [--device "iPhone 17"]
#
# Render: runs the snapshot tests (platforms/apple/Tests/WestronSnapshotTests), which draw every sheet of every matrix
# (generated from the contracts into WestronCatalog/Generated/) and of its supplements in light, dark, light-hc and
# dark-hc at the default text size, and on iOS in light at xSmall and accessibility5 (macOS has no Dynamic Type); with
# --component, of the components it names only (repeated or comma-separated). On macOS they run under `swift test` in
# an offscreen window; on iOS in the catalog app on the simulator (--device, default iPhone 17 or $WESTRON_SIM_DEVICE),
# as the unit-test bundle CatalogSnapshotTests, built incrementally. The PNGs, named
# <component>.<sheet>[_part-<n>-of-<count>].<theme>.png and <component>.<sheet>[_part-<n>-of-<count>].light.<text
# size>.png (a part where the sheet's cells do not fit side by side, or at accessibility5 on the screen), the manifest
# matrix.json, environment.json (the environment, below) and the review page index.html go to DIR, by default
# .build/snapshot-matrix/<platform>/; the script prints the images per component, the time, and the path of index.html
# last, and fails when a picture failed (a blank render drawn again until it gave up, a sheet that does not fit, a cell
# squeezed below the width it needs even one column to a picture) or an image is missing. Log:
# .build/logs/snapshot-matrix-<platform>.log, with each picture's time.
# The sheets are laid out for the default device, iPhone 17 in portrait: at accessibility5 a part of one column and six
# rows just fits it, so another --device, a shorter one above all, may fail the check that every cell is inside the
# window there.
#
# Compare: compares two renders image by image and writes a report page (before, after and a diff side by side), by
# default to .build/snapshot-matrix/compare/; prints what changed, by component, and the page's path; exits 0 when
# every image is the same and 1 when one changed, was added or was removed. A pixel whose every channel differs by at
# most N levels (--tolerance, default 1) counts as the same: renders in one environment drift by a level in a few
# pixels from run to run. Only renders from the same environment compare (decisions/0008): two local renders, before
# and after a change, on one Mac and simulator.
#
# Check: compares a render (DIR with --from, else a fresh full render) with the references of the platform and writes
# the report to .build/snapshot-matrix/check-<platform>/ (--out). The environment is what besides the code changes a
# picture: the Mac's macOS and processor, Xcode, and on iOS the simulator's runtime and device, and the scale; the
# references record theirs in platforms/apple/Snapshots/<platform>/environment.json. Exit status:
#   0  every image is the same as its reference, within the tolerance
#   1  an image changed, was added or was removed (the report says which), or the render failed
#   2  wrong arguments
#   3  no references recorded yet for the platform
#   4  the environment differs from the references': nothing is compared. Elsewhere than on the CI runner the
#      references were made on, this is the normal outcome; render before and after a change and `compare` them.
# Record: writes the render (--from, else a fresh full render) into the references and its environment beside them.
# A reference within the tolerance of its new picture stays as it was, so a drift does not rewrite it; in another
# environment only the same pixels keep one. CI records them (.github/workflows/snapshot-references.yml): references
# recorded elsewhere would not match the runner's renders.
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

references_of() { echo "$root/platforms/apple/Snapshots/$1"; }

# Prints, as JSON, what besides the code changes a render of <platform> (with the simulator <udid> on iOS): the Mac's
# macOS and processor (Core Animation draws on its GPU, the simulator's too), Xcode, and on iOS the simulator's runtime
# and device type. The render adds the scale and the number of images. On a GitHub runner it also names the runner
# image and its version (`image`), for the reader only: an image's weekly version changes no picture by itself, so it
# is not compared.
environment_json() {
  local platform="$1" udid="${2:-}" xcode runtime="" device="" ids
  xcode="$(xcodebuild -version | awk 'NR == 1 { v = $2 } NR == 2 { b = $3 } END { print v " (" b ")" }')"
  if [ "$platform" = ios ]; then
    ids="$(xcrun simctl list devices -j | jq -r --arg udid "$udid" \
      '.devices | to_entries[] | .key as $runtime | .value[] | select(.udid == $udid)
        | "\($runtime) \(.deviceTypeIdentifier)"')"
    runtime="$(xcrun simctl list runtimes -j | jq -r --arg id "${ids%% *}" \
      '.runtimes[] | select(.identifier == $id) | "\(.name) (\(.buildversion))"')"
    device="$(xcrun simctl list devicetypes -j | jq -r --arg id "${ids#* }" \
      '.devicetypes[] | select(.identifier == $id) | .name')"
  fi
  jq -n --arg platform "$platform" --arg macos "$(sw_vers -productVersion) ($(sw_vers -buildVersion))" \
    --arg machine "$(sysctl -n machdep.cpu.brand_string)" --arg xcode "$xcode" --arg runtime "$runtime" \
    --arg device "$device" --arg image "${ImageOS:+$ImageOS ${ImageVersion:-}}" '
    {platform: $platform, macos: $macos, machine: $machine, xcode: $xcode}
    + (if $runtime != "" then {runtime: $runtime, device: $device} else {} end)
    + (if $image != "" then {image: $image} else {} end)'
}

# Prints what makes the render in <dir> unfit to check or record, one line each: a picture of the manifest without a
# result (its render failed), short of cells, cut off or with cells squeezed below the width they need, and a PNG the manifest does not name or a named one that is
# not there. Nothing when the render is complete.
incomplete() {
  local dir="$1"
  jq -r '.components[].groups[].sheets[].images[][]
    | if .found == null then "\(.file): no picture (its render failed)"
      elif .found != .cells then "\(.file): \(.found) of \(.cells) cells drew something"
      elif .fits == false then "\(.file): cut off"
      elif (.squeezed // 0) > 0 then "\(.file): \(.squeezed) cells squeezed below the width they need"
      else empty end' "$dir/matrix.json"
  diff <(jq -r '.. | objects | select(has("file")) | .file' "$dir/matrix.json" | sort) \
    <(find "$dir" -maxdepth 1 -name '*.png' -exec basename {} \; | sort) \
    | sed -n 's/^< \(.*\)/\1: named in the manifest, no PNG/p; s/^> \(.*\)/\1: a PNG the manifest does not name/p' \
    || true
}

# Prints the keys whose values differ between two environment files, one per line, `key: <a> / <b>`: neither the
# number of images nor the notes count, nor the scale unless <with> is `scale` (a render knows it, not the script).
environment_differences() {
  jq -rn --slurpfile a "$1" --slurpfile b "$2" --arg with "${3:-}" '
    ["platform", "macos", "machine", "xcode", "runtime", "device"] + (if $with == "scale" then ["scale"] else [] end)
    | .[] | select($a[0][.] != $b[0][.]) | "  \(.): \($a[0][.] // "none") / \($b[0][.] // "none")"'
}

# Whether the references of <platform> hold a recorded set.
recorded() {
  local file
  file="$(references_of "$1")/environment.json"
  [ -f "$file" ] && [ "$(jq -r '.recorded' "$file")" != false ]
}

# Finds the destination of <platform>: on iOS the simulator <device>, booted if need be (sets udid); on macOS the Mac.
destination() {
  udid=""
  if [ "$1" = ios ]; then
    # shellcheck source=tools/apple/simulator.sh
    source tools/apple/simulator.sh
    udid="$(westron_simulator_udid "$2")" || exit 1
  fi
}

# Renders <platform> with the components <list> (empty: all) into <out>; destination must have run. Sets
# render_status: 0, or 1 when the render failed.
render() {
  local platform="$1" component="$2" out="$3" log=".build/logs/snapshot-matrix-$1.log" start built finished
  local test_status=0 page_status=0 contract file
  mkdir -p "$out" .build/logs
  : > "$log"
  # Only a render's own files are removed, so DIR can hold other files: the images the previous manifest names, any
  # <component>.*.png of a component in spec/components (a render that failed before its manifest), the manifest, the
  # environment and the page.
  if [ -f "$out/matrix.json" ]; then
    { jq -r '.. | objects | select(has("file")) | .file' "$out/matrix.json" 2> /dev/null || true; } \
      | while read -r file; do
        case "$file" in */* | "") ;; *) rm -f -- "$out/$file" ;; esac
      done
  fi
  for contract in spec/components/*/; do
    rm -f -- "$out/$(basename "$contract")."*.png
  done
  rm -f -- "$out/matrix.json" "$out/environment.json" "$out/index.html"

  start=$SECONDS
  if [ "$platform" = macos ]; then
    echo "== snapshot-matrix: macOS, swift test${component:+, $component}" >&2
    if ! swift build --build-tests >> "$log" 2>&1; then
      grep -E "error:" "$log" | head -20 >&2 || true
      echo "snapshot-matrix: build failed, log: $log" >&2
      render_status=1
      return 0
    fi
    built=$SECONDS
    WESTRON_SNAPSHOTS="$out" WESTRON_SNAPSHOTS_COMPONENT="$component" \
      swift test --skip-build --filter WestronSnapshotTests >> "$log" 2>&1 || test_status=$?
  else
    echo "== snapshot-matrix: id=$udid, CatalogSnapshotTests${component:+, $component}" >&2
    local xcodebuild_args=(-project platforms/apple/Catalog/Catalog.xcodeproj -scheme Catalog -destination "id=$udid"
      -derivedDataPath .build/xcode/catalog)
    if ! xcodebuild "${xcodebuild_args[@]}" build-for-testing >> "$log" 2>&1; then
      grep -E "error:|BUILD FAILED" "$log" | grep -v "\[MT\]" | head -20 >&2 || true
      echo "snapshot-matrix: build failed, log: $log" >&2
      render_status=1
      return 0
    fi
    built=$SECONDS
    # The test runner passes TEST_RUNNER_<name> to the test as <name>. Without -collect-test-diagnostics never, a
    # failed run waits minutes for a sysdiagnose of the simulator.
    TEST_RUNNER_WESTRON_SNAPSHOTS="$out" TEST_RUNNER_WESTRON_SNAPSHOTS_COMPONENT="$component" \
      xcodebuild "${xcodebuild_args[@]}" test-without-building -only-testing:CatalogSnapshotTests \
      -testLanguage en -testRegion en_US -collect-test-diagnostics never >> "$log" 2>&1 || test_status=$?
  fi
  finished=$SECONDS

  # The test's failures, each with its message, its summary line, and on macOS the languages before the pin, the text
  # metrics at the start and the end, the pictures drawn again at the end, and the process's state when a check of
  # reproducibility failed (#99).
  awk '/\[MT\]/ { next }
    /✘ .*recorded an issue/ { if ((getline line) > 0 && line ~ /^↳ /) print line; next }
    / draws: |^snapshot: [0-9]+ images|^snapshot: (languages before|text metrics|drawn again|state)|: error: |\*\* TEST/ {
      print
    }' \
    "$log" >&2
  if [ ! -f "$out/matrix.json" ]; then
    echo "snapshot-matrix: the test wrote no manifest (status $test_status), log: $log" >&2
    render_status=1
    return 0
  fi
  jq -r '.components[] | "  \(.component): \([.groups[].sheets[].images[][] | select(.found != null)] | length) images"' \
    "$out/matrix.json" >&2
  environment_json "$platform" "$udid" \
    | jq --slurpfile manifest "$out/matrix.json" --argjson images "$(find "$out" -maxdepth 1 -name '*.png' | wc -l)" \
      --arg component "$component" '. + {scale: $manifest[0].scale, images: $images}
        + (if $component != "" then {partial: $component} else {} end)' > "$out/environment.json"
  echo "snapshot-matrix: build $((built - start)) s, render $((finished - built)) s (log: $log)" >&2
  pages index "$out" || page_status=$?
  render_status=0
  if [ "$test_status" -ne 0 ] || [ "$page_status" -ne 0 ]; then
    echo "snapshot-matrix: the render failed (test status $test_status), log: $log" >&2
    render_status=1
  fi
}

case "${1:-}" in
  compare)
    shift
    [ $# -ge 2 ] || usage
    before="$(absolute "$1")" after="$(absolute "$2")"
    shift 2
    out=".build/snapshot-matrix/compare" tolerance=1
    while [ $# -gt 0 ]; do
      case "$1" in
        --out) out="$2"; shift 2 ;;
        --tolerance) tolerance="$2"; shift 2 ;;
        *) usage ;;
      esac
    done
    out="$(absolute "$out")"
    mkdir -p "$out"
    status=0
    pages compare "$before" "$after" "$out" --tolerance "$tolerance" || status=$?
    [ "$status" -le 1 ] || exit "$status"
    echo "$out/index.html"
    exit "$status"
    ;;

  check | record)
    command="$1" platform="${2:-}"
    [ "$platform" = ios ] || [ "$platform" = macos ] || usage
    shift 2
    from="" device="${WESTRON_SIM_DEVICE:-iPhone 17}" out=".build/snapshot-matrix/check-$platform" tolerance=1
    while [ $# -gt 0 ]; do
      case "$1" in
        --from) from="$2"; shift 2 ;;
        --device) device="$2"; shift 2 ;;
        --out) [ "$command" = check ] || usage; out="$2"; shift 2 ;;
        --tolerance) tolerance="$2"; shift 2 ;;
        *) usage ;;
      esac
    done
    references="$(references_of "$platform")"
    out="$(absolute "$out")"

    if [ "$command" = check ] && ! recorded "$platform"; then
      echo "snapshot-matrix: no references recorded yet for $platform: nothing to compare with." >&2
      echo "snapshot-matrix: CI records them (.github/workflows/snapshot-references.yml: by hand on a branch, or the" \
        "label record-snapshots on a pull request); see platforms/apple/Snapshots/README.md." >&2
      exit 3
    fi
    # The render: one given, else a fresh full one, after the environment is known to match (no point otherwise).
    if [ -n "$from" ]; then
      render_dir="$(absolute "$from")"
      [ -f "$render_dir/environment.json" ] && [ -f "$render_dir/matrix.json" ] || {
        echo "snapshot-matrix: $render_dir is not a render of tools/apple/snapshot-matrix.sh (no environment.json" \
          "or matrix.json)" >&2
        exit 2
      }
    else
      destination "$platform" "$device"
      render_dir="$root/.build/snapshot-matrix/$platform"
      if [ "$command" = check ]; then
        current="$(mktemp)"
        environment_json "$platform" "$udid" > "$current"
        differences="$(environment_differences "$references/environment.json" "$current")"
        rm -f "$current"
        if [ -n "$differences" ]; then
          echo "snapshot-matrix: this environment differs from the one the $platform references were recorded in" \
            "(references / here):" >&2
          echo "$differences" >&2
          echo "snapshot-matrix: nothing compared; pictures from another environment differ in every image" \
            "(decisions/0008). Render before and after your change here and compare those two instead:" >&2
          echo "  tools/apple/snapshot-matrix.sh $platform --out <before>; <change>;" \
            "tools/apple/snapshot-matrix.sh $platform; tools/apple/snapshot-matrix.sh compare <before>" \
            ".build/snapshot-matrix/$platform" >&2
          exit 4
        fi
      fi
      render "$platform" "" "$render_dir"
      [ "$render_status" -eq 0 ] || exit 1
    fi
    if [ "$(jq -r '.partial // ""' "$render_dir/environment.json")" != "" ]; then
      echo "snapshot-matrix: $render_dir holds some components only ($(jq -r .partial "$render_dir/environment.json"));" \
        "$command takes a full render" >&2
      exit 2
    fi
    if [ "$(jq -r .platform "$render_dir/environment.json")" != "$platform" ]; then
      echo "snapshot-matrix: $render_dir is not a render of $platform" >&2
      exit 2
    fi
    # A render with a failed picture is neither checked nor recorded: a missing PNG would read as a removed sheet, and
    # record would delete its reference.
    problems="$(incomplete "$render_dir")"
    if [ -n "$problems" ]; then
      echo "snapshot-matrix: $command: the render in $render_dir is incomplete, so nothing is" \
        "$([ "$command" = check ] && echo compared || echo recorded):" >&2
      while IFS= read -r line; do echo "  $line"; done <<< "$problems" >&2
      exit 1
    fi

    if [ "$command" = check ]; then
      differences="$(environment_differences "$references/environment.json" "$render_dir/environment.json" scale)"
      if [ -n "$differences" ]; then
        echo "snapshot-matrix: the render's environment differs from the one the $platform references were" \
          "recorded in (references / render):" >&2
        echo "$differences" >&2
        echo "snapshot-matrix: nothing compared (decisions/0008). On CI: the runner image changed under the" \
          "references; record them again (.github/workflows/snapshot-references.yml). Elsewhere: render before and" \
          "after your change and compare those two (tools/apple/snapshot-matrix.sh compare)." >&2
        exit 4
      fi
      status=0
      mkdir -p "$out"
      pages compare "$references" "$render_dir" "$out" --tolerance "$tolerance" --labels reference,new \
        || status=$?
      [ "$status" -le 1 ] || exit "$status"
      echo "$out/index.html"
      if [ "$status" -eq 0 ]; then
        echo "snapshot-matrix: $platform matches its references" >&2
      else
        echo "snapshot-matrix: $platform differs from its references; the report shows each change. If the change" \
          "is intended, record the references on CI (label record-snapshots on the pull request)." >&2
      fi
      exit "$status"
    fi

    # record: in another environment, or over no references, only the same pixels keep a reference.
    keep="$tolerance"
    if ! recorded "$platform" \
      || [ -n "$(environment_differences "$references/environment.json" "$render_dir/environment.json" scale)" ]; then
      keep=0
    fi
    mkdir -p "$references"
    pages sync "$render_dir" "$references" --tolerance "$keep"
    jq --argjson images "$(find "$references" -maxdepth 1 -name '*.png' | wc -l)" '. + {images: $images}' \
      "$render_dir/environment.json" > "$references/environment.json"
    echo "snapshot-matrix: recorded the $platform references in ${references#"$root"/}: $(jq -c . \
      "$references/environment.json")" >&2
    exit 0
    ;;
esac

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
destination "$platform" "$device"
render "$platform" "$component" "$out"
echo "$out/index.html"
exit "$render_status"
