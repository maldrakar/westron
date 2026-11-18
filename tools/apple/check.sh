#!/usr/bin/env bash
# Checks for the Swift part of westron. CI and the agent's Stop hook run the same checks.
#
#   tools/apple/check.sh package     swift build + swift test (macOS)
#   tools/apple/check.sh package-ios the package's unit tests on the iOS simulator (iPhone 17 or $WESTRON_SIM_DEVICE)
#   tools/apple/check.sh platforms   compile the package for iOS and watchOS
#   tools/apple/check.sh catalog     build the catalog and UI tests for the iOS simulator and macOS
#   tools/apple/check.sh a11y [ios|macos] [test …]
#                                    accessibility audit of every catalog entry (default: the iOS simulator), in the
#                                    configurations named (testDefaultSettings testAccessibilityDynamicType
#                                    testIncreasedContrast testDarkAppearance testDarkIncreasedContrast; default: all);
#                                    WESTRON_ENTRY=<id>[,<id>…] limits it to those entries, WESTRON_ENTRY_SHARD=<i>/<n>
#                                    then to every n-th of them from the i-th; a run that fails for infrastructure
#                                    (a stalled simulator) is retried once for the entries it hit, never for a
#                                    finding (#74); WESTRON_A11Y_FAIL_ONCE=<id> fakes such a failure to show it
#   tools/apple/check.sh format      swift format lint without changes, tools/ included
#   tools/apple/check.sh fix-format  swift format that rewrites the files, tools/ included
#   tools/apple/check.sh all         everything except fix-format and a11y (package-ios included)
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

# The same unit tests as `package`, through xcodebuild on the iOS simulator: there they take the iOS branches of the
# code (the loading indicator, the label kind's layout), which `swift test` on macOS never reaches. It prints the
# failures and each test target's totals ("Test run with <n> tests in <m> suites"); the full log is in .build/logs/.
package_ios() {
  local udid log=.build/logs/package-ios.log status=0
  # shellcheck source=tools/apple/simulator.sh
  source tools/apple/simulator.sh
  udid="$(westron_simulator_udid "${WESTRON_SIM_DEVICE:-iPhone 17}")" || return 1
  mkdir -p .build/logs
  echo "== package-ios: id=$udid"
  # Without -collect-test-diagnostics never, a failed run waits minutes for a sysdiagnose of the simulator.
  xcodebuild -scheme Westron-Package -destination "id=$udid" -derivedDataPath .build/xcode/package \
    -collect-test-diagnostics never test > "$log" 2>&1 || status=$?
  stop_test_daemon "$udid"
  # The failures, each issue with the first line under it (its message), and the totals of each test target.
  awk '/\[MT\]/ { next }
    /✘ .*recorded an issue/ { print; if ((getline line) > 0 && line ~ /^↳ /) print line; next }
    /✘ |: error: |Test run with|\*\* TEST/ { print }' "$log"
  if [ "$status" -ne 0 ]; then
    echo "check.sh: package tests on the iOS simulator failed, log: $log" >&2
    return 1
  fi
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
  echo "== stopping the test daemon of the simulator $udid"
  xcrun simctl spawn "$udid" launchctl kill SIGKILL system/com.apple.testmanagerd > /dev/null 2>&1 || true
}

# An interrupted audit: stops its xcodebuild and the simulator's test daemon, then exits with <status>. The `|| true`:
# under `set -e`, the wait for the killed xcodebuild (status 143) would end the script before the daemon is stopped.
a11y_interrupted() {
  local udid="$1" status="$2"
  kill "$a11y_xcodebuild" 2> /dev/null || true
  wait "$a11y_xcodebuild" 2> /dev/null || true
  stop_test_daemon "$udid"
  exit "$status"
}

# Runs xcodebuild <action> for the audit into <log> and <results> on <destination>, with the -only-testing arguments
# after them; prints what the run reported and returns xcodebuild's status. Without -collect-test-diagnostics never, a
# failed run waits minutes for a sysdiagnose of the simulator. xcodebuild runs in the background and the script waits
# for it, so that an interruption reaches the traps at once; however the run ends, the simulator's test daemon is
# stopped (stop_test_daemon), and an interruption exits with the shell's status for its signal, 130 for INT and 143
# for TERM.
a11y_run() {
  local action="$1" log="$2" results="$3" destination="$4" udid="$5" status=0
  shift 5
  rm -rf "$results"
  xcodebuild -project platforms/apple/Catalog/Catalog.xcodeproj -scheme Catalog -destination "$destination" \
    -derivedDataPath .build/xcode/catalog -resultBundlePath "$results" -collect-test-diagnostics never \
    "$@" "$action" > "$log" 2>&1 &
  a11y_xcodebuild=$!
  trap 'a11y_interrupted "$udid" 130' INT
  trap 'a11y_interrupted "$udid" 143' TERM
  wait "$a11y_xcodebuild" || status=$?
  trap - INT TERM
  stop_test_daemon "$udid"
  # The issues the audit found, suppressed and deferred, each failure with its kind, then the test cases and the
  # totals. The test's lines of which entry starts and finishes are for a11y_plan alone.
  grep -E "^a11y: |: error: |Test Case .*(passed|failed)|Executed [0-9]+ test" "$log" | grep -v "\[MT\]" \
    | grep -vE "^a11y: test[A-Za-z]+: (entries|started|finished) " || true
  return "$status"
}

# What a failed run of the audit test <test> leaves to do, from the lines CatalogAccessibilityAuditTests prints into
# <log>: `pass` (the test passed), `retry <ids>` (the entries to audit once more: the ones the run did not finish, or
# that failed for infrastructure alone; `*` for all of them, when the test audited nothing) or `fail` (a finding, a
# failure outside an entry, or a failure the lines do not explain). An entry with a finding is never retried.
a11y_plan() {
  local log="$1" test="$2"
  awk -v test="$test" -v q="'" '
    function after(prefix) { return substr($0, length(prefix) + 1) }
    BEGIN { p = "a11y: " test ": " }
    index($0, "Test Case " q "-[CatalogUITests.CatalogAccessibilityAuditTests " test "]" q " passed") { passed = 1 }
    index($0, p "entries ") == 1 { count = split(after(p "entries "), entries, ",") }
    index($0, p "finished ") == 1 { finished[after(p "finished ")] = 1 }
    index($0, p "failure in ") == 1 {
      rest = after(p "failure in ")
      entry = substr(rest, 1, index(rest, " (") - 1)
      if (index(rest, " (infrastructure): ") == length(entry) + 1) infrastructure[entry] = 1
      else finding[entry] = 1
    }
    index($0, p "failure outside an entry ") == 1 { outside = 1 }
    END {
      if (passed) { print "pass"; exit }
      if (outside) { print "fail"; exit }
      if (count == 0) { print "retry *"; exit }
      for (i = 1; i <= count; i++) if (entries[i] in finding) { print "fail"; exit }
      list = ""
      for (i = 1; i <= count; i++)
        if (!(entries[i] in finished) || (entries[i] in infrastructure)) list = list (list == "" ? "" : ",") entries[i]
      print (list == "" ? "fail" : "retry " list)
    }' "$log"
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
  # A test hook: WESTRON_A11Y_FAIL_ONCE=<id> fails that entry for infrastructure in the first run only, to show the
  # retry below at work.
  if [ -n "${WESTRON_A11Y_FAIL_ONCE:-}" ]; then export TEST_RUNNER_WESTRON_A11Y_FAIL_ONCE="$WESTRON_A11Y_FAIL_ONCE"; fi
  mkdir -p .build/logs .build/xcode/results
  echo "== a11y: $destination${selection:+ (${selection#-})}"
  if a11y_run test "$log" "$results" "$destination" "$udid" "${only[@]}"; then return 0; fi
  if grep -q "BUILD FAILED" "$log"; then
    echo "check.sh: accessibility audit failed to build ($platform), log: $log" >&2
    return 1
  fi

  # The run failed. On the CI runner the simulator now and then stalls, and XCTest fails what the test asks of it then
  # (#74): an entry the stall hit is audited once more, in a run of its own, and so are the entries a stopped test
  # method did not reach. An entry with a finding is never audited again, and nor is any entry of a test with one, so
  # a finding fails the run however rarely it shows.
  local failed=0 plan entries what retry_name retry_log retry_results
  local first_entry="${TEST_RUNNER_WESTRON_ENTRY:-}" first_shard="${TEST_RUNNER_WESTRON_ENTRY_SHARD:-}"
  unset TEST_RUNNER_WESTRON_A11Y_FAIL_ONCE
  [ $# -gt 0 ] || set -- "${a11y_tests[@]}"
  for test in "$@"; do
    plan="$(a11y_plan "$log" "$test")"
    case "$plan" in
      pass) continue ;;
      fail)
        echo "check.sh: a11y: $test failed with a finding, or with a failure that is not the infrastructure's" >&2
        failed=1
        continue
        ;;
    esac
    entries="${plan#retry }"
    what="$test for ${entries/#\*/all its entries}"
    echo "a11y: retrying $what: the first run failed for infrastructure (log: $log)"
    if [ -n "${GITHUB_ACTIONS:-}" ]; then
      echo "::warning title=Accessibility audit retried::$what: the first run failed for infrastructure; see $log"
    fi
    retry_name="$name-retry-$test"
    retry_log=".build/logs/$retry_name.log" retry_results=".build/xcode/results/$retry_name.xcresult"
    # The simulator may have died with the run; it is found, and booted again if need be.
    if [ "$platform" = ios ]; then
      udid="$(westron_simulator_udid "${WESTRON_SIM_DEVICE:-iPhone 17}")" || return 1
      destination="id=$udid"
    fi
    if [ "$entries" != "*" ]; then
      # The entries to retry are already the shard's, so the shard is not taken again.
      export TEST_RUNNER_WESTRON_ENTRY="$entries"
      unset TEST_RUNNER_WESTRON_ENTRY_SHARD
    else
      # All of the first run's selection, as it was.
      unset TEST_RUNNER_WESTRON_ENTRY TEST_RUNNER_WESTRON_ENTRY_SHARD
      if [ -n "$first_entry" ]; then export TEST_RUNNER_WESTRON_ENTRY="$first_entry"; fi
      if [ -n "$first_shard" ]; then export TEST_RUNNER_WESTRON_ENTRY_SHARD="$first_shard"; fi
    fi
    if ! a11y_run test-without-building "$retry_log" "$retry_results" "$destination" "$udid" \
      "-only-testing:CatalogUITests/CatalogAccessibilityAuditTests/$test"; then
      echo "check.sh: a11y: $test failed again on its retry, log: $retry_log, result: $retry_results" >&2
      failed=1
    fi
  done
  if [ "$failed" -ne 0 ]; then
    grep -E "TEST FAILED|\*\* TEST" "$log" | tail -5 >&2 || true
    echo "check.sh: accessibility audit failed ($platform), log: $log, result: $results" >&2
    return 1
  fi
  echo "a11y: passed after a retry; the first run's log: $log"
}

format() {
  swift format lint --strict --recursive --parallel "${swift_sources[@]}"
}

fix_format() {
  swift format format --in-place --recursive --parallel "${swift_sources[@]}"
}

case "${1:-}" in
  package) package ;;
  package-ios) package_ios ;;
  platforms) platforms ;;
  catalog) catalog ;;
  a11y) shift; a11y "$@" ;;
  format) format ;;
  fix-format) fix_format ;;
  all) format; package; package_ios; platforms; catalog ;;
  *) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
