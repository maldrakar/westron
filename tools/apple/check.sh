#!/usr/bin/env bash
# Checks for the Swift part of westron. CI and the agent's Stop hook run the same checks.
#
#   tools/apple/check.sh package     swift build + swift test (macOS)
#   tools/apple/check.sh platforms   compile the package for iOS and watchOS
#   tools/apple/check.sh catalog     build the catalog and UI tests for the iOS simulator and macOS
#   tools/apple/check.sh a11y [ios|macos] [test …]
#                                    accessibility audit of every catalog entry (default: the iOS simulator), in the
#                                    configurations named (testDefaultSettings testAccessibilityDynamicType
#                                    testIncreasedContrast testDarkAppearance testDarkIncreasedContrast; default: all);
#                                    WESTRON_ENTRY=<id>[,<id>…] limits it to those entries, WESTRON_ENTRY_SHARD=<i>/<n>
#                                    then to every n-th of them from the i-th
#   tools/apple/check.sh format      swift format lint without changes, tools/ included
#   tools/apple/check.sh fix-format  swift format that rewrites the files, tools/ included
#   tools/apple/check.sh all         everything except fix-format and a11y
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
# shellcheck source=tools/apple/xcode-env.sh
source tools/apple/xcode-env.sh

swift_sources=(Package.swift platforms/apple tools/Package.swift tools/Sources tools/Tests)
min_ios="$(sed -n 's/.*\.iOS(\.v\([0-9]*\)).*/\1/p' Package.swift).0"
min_watchos="$(sed -n 's/.*\.watchOS(\.v\([0-9]*\)).*/\1/p' Package.swift).0"

package() {
  swift build
  swift test
}

platforms() {
  swift build --triple "arm64-apple-ios$min_ios" --sdk "$(xcrun --sdk iphoneos --show-sdk-path)"
  swift build --triple "arm64_32-apple-watchos$min_watchos" --sdk "$(xcrun --sdk watchos --show-sdk-path)"
}

catalog() {
  local destination log=.build/logs/catalog-build.log
  mkdir -p .build/logs
  for destination in "generic/platform=iOS Simulator" "platform=macOS,arch=$(uname -m)"; do
    echo "== catalog: $destination"
    if ! xcodebuild -project platforms/apple/Catalog/Catalog.xcodeproj -scheme Catalog -destination "$destination" \
      -derivedDataPath .build/xcode/catalog build-for-testing > "$log" 2>&1; then
      grep -E "error:|warning:|FAILED" "$log" | grep -v "\[MT\]" | tail -40 >&2
      echo "check.sh: catalog build failed ($destination), log: $log" >&2
      return 1
    fi
  done
}

# The CatalogAccessibilityAuditTests UI test: performAccessibilityAudit on every catalog entry in several
# configurations, one test method each. With no test named, all of them run. iOS runs on $WESTRON_SIM_DEVICE
# (default iPhone 17); macOS needs Automation Mode (platforms/apple/README.md) and the screen to itself.
a11y_tests=(testDefaultSettings testAccessibilityDynamicType testIncreasedContrast testDarkAppearance
  testDarkIncreasedContrast)

# Stops the test daemon of the simulator <udid> after an audit (nothing for macOS, whose udid is empty). After an
# accessibility audit run, the simulator's testmanagerd has been seen to keep running at 400–1400 % CPU for hours,
# with no xcodebuild left (2026-11-17, iPhone 17 Pro, iOS 26.3). It is launchd's on-demand service in the simulator,
# so it is killed through launchctl and starts again when the next test connects; the simulator stays booted. A
# daemon that another xcodebuild on the same simulator still uses is left alone.
stop_test_daemon() {
  local udid="${1:-}"
  [ -n "$udid" ] || return 0
  if pgrep -f "xcodebuild.*-destination id=$udid" > /dev/null; then
    echo "check.sh: another xcodebuild uses the simulator $udid; its testmanagerd is left running" >&2
    return 0
  fi
  echo "== a11y: stopping the test daemon of the simulator $udid"
  xcrun simctl spawn "$udid" launchctl kill SIGKILL system/com.apple.testmanagerd > /dev/null 2>&1 || true
}

a11y() {
  local platform=ios destination udid="" test name
  case "${1:-}" in ios | macos) platform="$1"; shift ;; esac
  local only=() selection=""
  for test in "$@"; do
    if [[ " ${a11y_tests[*]} " != *" $test "* ]]; then
      echo "check.sh: a11y: no test \"$test\"; the tests: ${a11y_tests[*]}" >&2
      return 2
    fi
    only+=("-only-testing:CatalogUITests/CatalogAccessibilityAuditTests/$test")
    selection+="-$test"
  done
  [ ${#only[@]} -gt 0 ] || only=("-only-testing:CatalogUITests/CatalogAccessibilityAuditTests")
  # The selection is in the names, so that runs of different tests side by side keep their own log and result.
  name="a11y-$platform$selection"
  local log=".build/logs/$name.log" results=".build/xcode/results/$name.xcresult"
  case "$platform" in
    ios)
      # shellcheck source=tools/apple/simulator.sh
      source tools/apple/simulator.sh
      udid="$(westron_simulator_udid "${WESTRON_SIM_DEVICE:-iPhone 17}")" || return 1
      destination="id=$udid"
      ;;
    macos) destination="platform=macOS,arch=$(uname -m)" ;;
  esac
  # WESTRON_ENTRY=<id>[,<id>…] audits those entries only: to iterate on an entry's issues, or to split a run.
  if [ -n "${WESTRON_ENTRY:-}" ]; then export TEST_RUNNER_WESTRON_ENTRY="$WESTRON_ENTRY"; fi
  # WESTRON_ENTRY_SHARD=<i>/<n> then audits every n-th of them from the i-th: parallel jobs split a slow test with it.
  if [ -n "${WESTRON_ENTRY_SHARD:-}" ]; then
    export TEST_RUNNER_WESTRON_ENTRY_SHARD="$WESTRON_ENTRY_SHARD"
    name+="-shard${WESTRON_ENTRY_SHARD//\//of}"
    log=".build/logs/$name.log" results=".build/xcode/results/$name.xcresult"
  fi
  mkdir -p .build/logs .build/xcode/results
  rm -rf "$results"
  echo "== a11y: $destination${selection:+ (${selection#-})}"
  local status=0
  # Without -collect-test-diagnostics never, a failed run waits minutes for a sysdiagnose of the simulator. xcodebuild
  # runs in the background and the script waits for it, so that an interruption reaches the traps at once.
  xcodebuild -project platforms/apple/Catalog/Catalog.xcodeproj -scheme Catalog -destination "$destination" \
    -derivedDataPath .build/xcode/catalog -resultBundlePath "$results" -collect-test-diagnostics never \
    "${only[@]}" test > "$log" 2>&1 &
  a11y_xcodebuild=$!
  # However the run ends, the simulator's test daemon is stopped (stop_test_daemon).
  # The `|| true`: under `set -e`, the wait for the killed xcodebuild (status 143) would end the script before the stop.
  trap 'kill "$a11y_xcodebuild" 2>/dev/null || true; wait "$a11y_xcodebuild" 2>/dev/null || true
    stop_test_daemon "$udid"; exit 130' INT TERM
  wait "$a11y_xcodebuild" || status=$?
  trap - INT TERM
  stop_test_daemon "$udid"
  # The issues the audit found and suppressed, then the test cases and the totals.
  grep -E "^a11y: |: error: |Test Case .*(passed|failed)|Executed [0-9]+ test" "$log" | grep -v "\[MT\]" || true
  if [ "$status" -ne 0 ]; then
    grep -E "BUILD FAILED|TEST FAILED|\*\* TEST" "$log" | tail -5 >&2 || true
    echo "check.sh: accessibility audit failed ($platform), log: $log, result: $results" >&2
    return 1
  fi
}

format() {
  swift format lint --strict --recursive --parallel "${swift_sources[@]}"
}

fix_format() {
  swift format format --in-place --recursive --parallel "${swift_sources[@]}"
}

case "${1:-}" in
  package) package ;;
  platforms) platforms ;;
  catalog) catalog ;;
  a11y) shift; a11y "$@" ;;
  format) format ;;
  fix-format) fix_format ;;
  all) format; package; platforms; catalog ;;
  *) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
