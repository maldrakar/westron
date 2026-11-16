#!/usr/bin/env bash
# Checks for the Swift part of westron. CI and the agent's Stop hook run the same checks.
#
#   tools/apple/check.sh package     swift build + swift test (macOS)
#   tools/apple/check.sh platforms   compile the package for iOS and watchOS
#   tools/apple/check.sh catalog     build the catalog and UI tests for the iOS simulator and macOS
#   tools/apple/check.sh a11y [ios|macos]  accessibility audit of every catalog entry (default: the iOS simulator)
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
# configurations. iOS runs on $WESTRON_SIM_DEVICE (default iPhone 17); macOS needs Automation Mode
# (platforms/apple/README.md) and the screen to itself.
a11y() {
  local platform="${1:-ios}" destination udid
  local log=".build/logs/a11y-$platform.log" results=".build/xcode/results/a11y-$platform.xcresult"
  case "$platform" in
    ios)
      # shellcheck source=tools/apple/simulator.sh
      source tools/apple/simulator.sh
      udid="$(westron_simulator_udid "${WESTRON_SIM_DEVICE:-iPhone 17}")"
      destination="id=$udid"
      ;;
    macos) destination="platform=macOS,arch=$(uname -m)" ;;
    *) echo "check.sh: a11y takes ios or macos, not \"$platform\"" >&2; return 2 ;;
  esac
  # WESTRON_ENTRY=<id> audits one entry, to iterate on its issues.
  if [ -n "${WESTRON_ENTRY:-}" ]; then export TEST_RUNNER_WESTRON_ENTRY="$WESTRON_ENTRY"; fi
  mkdir -p .build/logs .build/xcode/results
  rm -rf "$results"
  echo "== a11y: $destination"
  local status=0
  # Without -collect-test-diagnostics never, a failed run waits minutes for a sysdiagnose of the simulator.
  xcodebuild -project platforms/apple/Catalog/Catalog.xcodeproj -scheme Catalog -destination "$destination" \
    -derivedDataPath .build/xcode/catalog -resultBundlePath "$results" -collect-test-diagnostics never \
    -only-testing:CatalogUITests/CatalogAccessibilityAuditTests test > "$log" 2>&1 || status=$?
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
  a11y) a11y "${2:-ios}" ;;
  format) format ;;
  fix-format) fix_format ;;
  all) format; package; platforms; catalog ;;
  *) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
