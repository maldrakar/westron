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
# fails when an expected image is missing or a sheet failed its checks. Log: .build/logs/. A capture the machinery
# failed (the app did not launch, the test runner did not start: a stalled simulator) is run once more, within
# WESTRON_MATRIX_RETRY_BY minutes (default 25) of the start; never one whose test reported a failure of a sheet. An
# xcodebuild whose log has not grown for WESTRON_MATRIX_STALL_SECONDS (default 600) is stopped, and a capture so
# stopped counts as the machinery's failure; at WESTRON_MATRIX_DEADLINE minutes from the start (if set) the script
# stops whatever it still does and exits 1.
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

# Finds the simulator, boots it if need be, and pins its status bar; on macOS, the Mac. Sets udid, destination and
# xcodebuild_args.
prepare_destination() {
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
}

# CI run 44461921450 printed the capture's header and then nothing for 62 minutes, until the job's timeout killed the
# leg, and a leg the timeout kills uploads no logs. Two guards keep that from happening again:
# - The watchdog over every xcodebuild of the script, the build and each capture: a run whose log has not grown for
#   WESTRON_MATRIX_STALL_SECONDS (default 600, 10 min) has stalled, and is stopped with its children; a line saying so
#   goes into its log for matrix_plan, which retries a stalled capture. A capture's longest usual silences are the
#   machinery's: the test runner starting (2.4 min on a stalled CI runner, run 44444325775), a launch timing out
#   (3 min) or the runner crashing while bootstrapping (3.5 min after "Running tests..."); between the test's own lines
#   no more than 2.3 s (local captures of every component, 1750 s on iOS and 709 s on macOS).
# - The deadline, WESTRON_MATRIX_DEADLINE minutes from the script's start (unset: none; CI sets it, .github/workflows/
#   ci.yml): then whatever the script still does, an xcodebuild, the export of the attachments, the page, is stopped,
#   and the script says which step it stopped and exits 1, with no retry, so that the logs upload before the timeout.
stall_after="${WESTRON_MATRIX_STALL_SECONDS:-600}"
deadline=""
[ -z "${WESTRON_MATRIX_DEADLINE:-}" ] || deadline=$((WESTRON_MATRIX_DEADLINE * 60))

# Prints the process <pid> and every process under it, parents first.
process_tree() {
  local child
  echo "$1"
  for child in $(pgrep -P "$1" || true); do process_tree "$child"; done
}

# Stops the processes <pid>… and their children: TERM, then KILL for what is left after 30 s. The trees are read
# first: a child of a process that has gone belongs to launchd, and pgrep -P no longer finds it.
stop_tree() {
  local tree pid alive waited=0
  tree="$(for pid in "$@"; do process_tree "$pid"; done)"
  # shellcheck disable=SC2086 # one pid per word
  kill -TERM $tree 2> /dev/null || true
  while [ "$waited" -lt 30 ]; do
    alive=""
    for pid in $tree; do kill -0 "$pid" 2> /dev/null && alive="$alive $pid"; done
    [ -n "$alive" ] || return 0
    sleep 1
    waited=$((waited + 1))
  done
  # shellcheck disable=SC2086
  kill -KILL $alive 2> /dev/null || true
}

# Stops the processes <pid>… of the script (an xcodebuild, the export, the page) and what they started. On macOS the
# test runner and the catalog it launched belong to launchd, not to xcodebuild: a stopped run's runner exits by
# itself, its catalog stays (seen locally), so whatever still runs from this checkout's build products is stopped too,
# a concurrent macOS check in the same checkout included. On iOS they run in the simulator, whose test daemon
# stop_test_daemon stops.
stop_run() {
  [ $# -eq 0 ] || stop_tree "$@"
  if [ "$platform" = macos ]; then pkill -f "$root/.build/xcode/catalog/Build/Products/" 2> /dev/null || true; fi
}

# After UI tests the simulator's testmanagerd has been seen to spin for hours (tools/apple/check.sh, a11y): it is
# stopped once no xcodebuild uses the simulator (nothing on macOS).
stop_test_daemon() {
  if [ -n "$udid" ] && ! pgrep -f "xcodebuild.*-destination id=$udid" > /dev/null; then
    xcrun simctl spawn "$udid" launchctl kill SIGKILL system/com.apple.testmanagerd > /dev/null 2>&1 || true
  fi
}

# Watches xcodebuild <pid> through its <log> once a second, in the background, until it ends or is stopped (above).
# The line goes into the log after a newline: xcodebuild's last output may lack one, and matrix_plan reads the line
# only at the start of a line.
watchdog() {
  local log="$1" pid="$2" size last=-1 quiet_since=$SECONDS quiet why
  while kill -0 "$pid" 2> /dev/null; do
    size=$(($(wc -c < "$log")))
    quiet=$((SECONDS - quiet_since))
    if [ "$size" -ne "$last" ]; then
      last="$size" quiet_since=$SECONDS
    elif [ "$quiet" -ge "$stall_after" ]; then
      why="stalled: xcodebuild wrote nothing for $((quiet / 60)) min $((quiet % 60)) s"
      echo "snapshot-matrix: $why (WESTRON_MATRIX_STALL_SECONDS=$stall_after); stopping it, log: $log" >&2
      printf '\nsnapshot-matrix: %s\n' "$why" >> "$log"
      stop_run "$pid"
      return 0
    fi
    sleep 1
  done
}

# An interrupted run: stops its xcodebuild and the watchdog, then exits with <status> (tools/apple/check.sh,
# a11y_interrupted). A background job of a script ignores SIGINT, so the interruption does not reach xcodebuild itself.
interrupted() {
  stop_run "$watched_pid"
  kill "$watchdog_pid" 2> /dev/null || true
  exit "$1"
}

# Runs xcodebuild <argument>… with its output appended to <log>, under the watchdog, and returns its status. It runs in
# the background and the script waits for it, so that an interruption reaches the traps at once, as in check.sh's
# a11y_run; a stopped run returns 143 (TERM) or 137 (KILL).
watched_xcodebuild() {
  local log="$1" status=0
  shift
  xcodebuild "$@" >> "$log" 2>&1 &
  watched_pid=$!
  watchdog "$log" "$watched_pid" &
  watchdog_pid=$!
  trap 'interrupted 130' INT
  trap 'interrupted 143' TERM
  wait "$watched_pid" || status=$?
  wait "$watchdog_pid" || true
  trap - INT TERM
  return "$status"
}

# The deadline (above), in the background: at it, the timer signals the script (USR1) and stops the script's other
# children, the step that runs among them; the script handles the signal once its own command has ended, at once when
# it waits for an xcodebuild. The timer ends with the script. Its own pid: bash 3.2 has no BASHPID, so a child that
# execs sh reports its parent.
deadline_timer() {
  local self child children=""
  self="$(exec sh -c 'echo "$PPID"')"
  while kill -0 $$ 2> /dev/null; do
    if [ "$SECONDS" -ge "$deadline" ]; then
      kill -USR1 $$ 2> /dev/null || return 0
      for child in $(pgrep -P $$ || true); do [ "$child" = "$self" ] || children="$children $child"; done
      # shellcheck disable=SC2086 # one pid per word
      stop_run $children
      return 0
    fi
    sleep 1
  done
}

# The script's side of the deadline: says which <step> it stopped, writes the same into the current log, stops what
# is left, and exits 1.
at_deadline() {
  local why="stopped at the deadline: $((SECONDS / 60)) min since the start, during $step"
  echo "snapshot-matrix: $why (WESTRON_MATRIX_DEADLINE=$((deadline / 60))), so that the logs upload before the job's" \
    "timeout; log: $log" >&2
  printf '\nsnapshot-matrix: %s\n' "$why" >> "$log"
  # shellcheck disable=SC2046 # one pid per word
  stop_run $(pgrep -P $$ | grep -vx "$deadline_timer_pid" || true)
  stop_test_daemon
  exit 1
}

if [ -n "$deadline" ]; then
  trap at_deadline USR1
  deadline_timer &
  deadline_timer_pid=$!
fi

step="finding the destination"
prepare_destination

step="the build (xcodebuild build-for-testing)"
: > "$log"
if ! watched_xcodebuild "$log" "${xcodebuild_args[@]}" build-for-testing; then
  grep -E "error:|BUILD FAILED" "$log" | head -20 >&2 || true
  echo "snapshot-matrix: build failed, log: $log" >&2
  exit 1
fi

export TEST_RUNNER_WESTRON_MATRIX=1
[ -n "$component" ] && export TEST_RUNNER_WESTRON_MATRIX_COMPONENT="$component"

# Runs the test once into <log> (appended) and <results>, and moves what it attached into $out: the PNGs and the
# manifest. Sets test_status to xcodebuild's status. Without -collect-test-diagnostics never, a failed run waits minutes
# for a sysdiagnose of the simulator. A failed test still exports what it captured, so the page shows what went wrong.
capture() {
  local log="$1" results="$2" attachments="${2%.xcresult}-attachments"
  rm -rf "$results" "$attachments"
  echo "== snapshot-matrix: $destination${component:+, $component}" >&2
  test_status=0
  step="the test run (xcodebuild test-without-building)"
  watched_xcodebuild "$log" "${xcodebuild_args[@]}" test-without-building -resultBundlePath "$results" \
    -collect-test-diagnostics never \
    -only-testing:CatalogUITests/SnapshotMatrixTests/testMatrix || test_status=$?
  grep -E "^matrix: |: error: |Failed to install or launch the test runner|Early unexpected exit" "$log" \
    | grep -v "\[MT\]" >&2 || true
  stop_test_daemon
  # A runner that never started leaves no result bundle: no manifest then, and matrix_plan below decides.
  step="the export of the attachments (xcresulttool)"
  if ! xcrun xcresulttool export attachments --path "$results" --output-path "$attachments" >> "$log" 2>&1; then
    echo "snapshot-matrix: no attachments in $results, log: $log" >&2
    return 0
  fi
  # The export names each file by its own id; its manifest.json maps them to the names the test gave the attachments,
  # which xcresulttool suggests as `<name without .png>_<n>_<UUID>.png`.
  step="moving the attachments"
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
}

# What a failed capture that wrote no manifest leaves to do, from its <log>. Prints one line:
#   retry <reason>  the machinery failed, not the capture: the test runner did not start (xcodebuild's "Failed to
#                   install or launch the test runner" or "Early unexpected exit, operation never finished
#                   bootstrapping", with no test case started and no failure), or the test started and every failure
#                   XCTest reported is one of its messages for a request to the simulator, below, or the watchdog
#                   stopped a run that had stalled (`retry stalled: …`) and the test reported no failure of its own;
#   fail <reason>   anything else: a failure of the test's own (a cell count that differs, a cell outside the window,
#                   a sheet that did not render or showed a problem, an unknown component), such a failure among
#                   others, stalled or not, a run with no failure that explains it (the runner died mid-run), a test
#                   that did not start otherwise, a test that passed.
# A real macOS xcodebuild the watchdog stops mid-test ends its output with "** BUILD INTERRUPTED **" and reports no
# failure of the test (seen locally), so a stall alone is retried.
# The machinery's messages, told by how they start, never by text further in: the XCTest messages that
# CatalogAccessibilityAuditTests.isInfrastructure counts as infrastructure (the same XCUIApplication calls), not that
# test's own failures:
#   "Failed to launch <XCUIApplicationImpl: …> via Xcode: Timed out while launching application" (CI run 44444325775,
#     the leg button+rule, at the first `app.launch()` of SnapshotMatrixTests);
#   "Failed to get background assertion for target app with pid <pid>: Timed out while acquiring …" (the same run, the
#     audit's testDefaultSettings 2/3, at its first `app.launch()`);
#   "Failed to terminate dev.westron.catalog:" and "Application 'dev.westron.catalog' does not have a process ID"
#     (the audit on CI, #74);
#   "Failed to <request>: Timed out while …" (a UI query on CI, #74; a drag and a screenshot locally).
matrix_plan() {
  awk -v q="'" '
    BEGIN { c = "-[CatalogUITests.SnapshotMatrixTests testMatrix]"; e = ": error: " c " : " }
    index($0, "Test Case " q c q " started") { started = 1 }
    index($0, "Test Case " q c q " passed") { passed = 1 }
    index($0, "Failed to install or launch the test runner") { runner = 1 }
    index($0, "Early unexpected exit, operation never finished bootstrapping") { runner = 1 }
    index($0, "snapshot-matrix: stalled: ") == 1 { stalled = substr($0, length("snapshot-matrix: ") + 1) }
    index($0, e) {
      errors++
      m = substr($0, index($0, e) + length(e))
      if (m ~ /^Failed to launch <XCUIApplicationImpl: [^>]+> via Xcode: Timed out while launching application/ \
        || m ~ /^Failed to get background assertion for target app with pid [0-9]+: Timed out while acquiring / \
        || index(m, "Failed to terminate dev.westron.catalog:") == 1 \
        || index(m, "Application " q "dev.westron.catalog" q " does not have a process ID") == 1 \
        || m ~ /^Failed to [a-z ]+: Timed out while /) machinery++
      else if (other == "") other = m
    }
    END {
      if (passed) { print "fail the test passed, yet wrote no manifest"; exit }
      if (stalled != "") {
        if (other != "") print "fail a failure of the capture: " other
        else print "retry " stalled
        exit
      }
      if (!started) {
        if (runner && errors == 0) print "retry the test runner did not start"
        else print "fail the test did not start"
        exit
      }
      if (errors == 0) { print "fail no failure of the test explains it"; exit }
      if (other != "") { print "fail a failure of the capture: " other; exit }
      printf "retry the simulator failed the test (%d failure%s of the machinery)\n", errors, (errors == 1 ? "" : "s")
    }' "$1"
}

# A retry starts only within this many minutes of the start of the script, its build included: it captures everything
# again, so it needs a whole capture's time. CI's snapshot legs time out at 30 minutes plus their estimated capture
# time with a third more (.github/workflows/ci.yml, `snapshot-components`): a retry that starts by 25 minutes, takes
# about 3 to start the test runner (2.4 on the stalled CI runner, run 44444325775) and captures within the third more,
# leaves about 2 minutes for the export, the page and the upload. A leg the timeout kills uploads no logs, so CI sets
# the deadline (above) at those 2 minutes before the timeout: a stall noticed 10 minutes late, in a retry or after a
# slow first run, or a step that hangs outside xcodebuild, would otherwise run into it.
retry_by=$((${WESTRON_MATRIX_RETRY_BY:-25} * 60))

# One test invocation for the whole matrix, and one retry when the machinery failed it (above), with a warning on
# GitHub Actions. The first run's log stays as $log, its build included; the retry's is <name>-retry.log.
results=".build/xcode/results/$name.xcresult"
capture "$log" "$results"
if [ ! -f "$out/matrix.json" ] && [ "$test_status" -ne 0 ]; then
  plan="$(matrix_plan "$log")"
  case "$plan" in
    retry*)
      if [ "$SECONDS" -gt "$retry_by" ]; then
        echo "snapshot-matrix: ${plan#retry }, not retried: $((SECONDS / 60)) min have gone, past the" \
          "$((retry_by / 60)) min a retry must start by (WESTRON_MATRIX_RETRY_BY)" >&2
      else
        echo "snapshot-matrix: retrying the capture: ${plan#retry }; its failures are above (log: $log)" >&2
        if [ -n "${GITHUB_ACTIONS:-}" ]; then
          echo "::warning title=Snapshot matrix retried::${component:-every component} on $platform:" \
            "${plan#retry }. The first run's failures are in this step's output; its log is in the leg's artifact."
        fi
        # The simulator may have died with the run; it is found, and booted again if need be.
        step="finding the destination again"
        prepare_destination
        log=".build/logs/$name-retry.log" results=".build/xcode/results/$name-retry.xcresult"
        : > "$log"
        capture "$log" "$results"
      fi
      ;;
    *) echo "snapshot-matrix: the capture failed, not retried: ${plan#fail }" >&2 ;;
  esac
fi

if [ ! -f "$out/matrix.json" ]; then
  echo "snapshot-matrix: the test wrote no manifest (status $test_status), log: $log" >&2
  exit 1
fi
page_status=0
step="the review page (snapshot-pages)"
pages index "$out" || page_status=$?
echo "$out/index.html"
if [ "$test_status" -ne 0 ] || [ "$page_status" -ne 0 ]; then
  echo "snapshot-matrix: the capture failed (test status $test_status), log: $log, result: $results" >&2
  exit 1
fi
