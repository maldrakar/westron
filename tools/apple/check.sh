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

# What a failed run of the audit test <test> leaves to do, from <log>. Prints one line:
#   pass            the test passed;
#   retry <ids>     the entries to audit once more: the ones the run did not finish, or that failed for infrastructure
#                   alone. Only after a run whose test started (it printed its `entries` line) and whose every failure
#                   the test classified: XCTest's own `error: -[… <test>]` lines are counted against the test's
#                   `failure …` lines, so a lost line cannot turn a finding into an unfinished entry;
#   retry *         all of the test's entries: the test runner failed to install or launch, so nothing was audited
#                   (seen once on CI, "Mach error -308 - (ipc/mig) server died");
#   fail <reason>   anything else: a finding, a failure outside an entry, an unclassified failure, a test that did
#                   not start (a build failure among them), a failure nothing explains.
# An entry with a finding is never retried, and nor is any entry of a test with one.
a11y_plan() {
  local log="$1" test="$2"
  awk -v test="$test" -v q="'" '
    function after(prefix) { return substr($0, length(prefix) + 1) }
    BEGIN { p = "a11y: " test ": "; c = "-[CatalogUITests.CatalogAccessibilityAuditTests " test "]" }
    index($0, "Test Case " q c q " passed") { passed = 1 }
    index($0, ": error: " c " : ") { errors++ }
    index($0, "Failed to install or launch the test runner") { install = 1 }
    index($0, p "entries ") == 1 { count = split(after(p "entries "), entries, ",") }
    index($0, p "finished ") == 1 { finished[after(p "finished ")] = 1 }
    index($0, p "failure in ") == 1 {
      classified++
      rest = after(p "failure in ")
      entry = substr(rest, 1, index(rest, " (") - 1)
      if (index(rest, " (infrastructure): ") == length(entry) + 1) infrastructure[entry] = 1
      else finding[entry] = 1
    }
    index($0, p "failure outside an entry ") == 1 { classified++; outside = 1 }
    END {
      if (passed) { print "pass"; exit }
      if (outside) { print "fail a failure outside an entry"; exit }
      if (count == 0) {
        if (install && classified == 0 && errors == 0) print "retry *"
        else print "fail the test did not start"
        exit
      }
      if (errors > classified) {
        printf "fail XCTest reported %d failures, the test classified %d\n", errors, classified
        exit
      }
      for (i = 1; i <= count; i++) if (entries[i] in finding) { print "fail a finding in " entries[i]; exit }
      list = ""
      for (i = 1; i <= count; i++)
        if (!(entries[i] in finished) || (entries[i] in infrastructure)) list = list (list == "" ? "" : ",") entries[i]
      print (list == "" ? "fail no failure of the test explains it" : "retry " list)
    }' "$log"
}

# The retry's time budget, in minutes from the start of `check.sh a11y`, its build included (#74). A CI leg times out
# at 35 minutes, and a leg killed by the timeout uploads no logs; before the step come about 1 minute of checkout and
# setup, after it the upload, 16 s for 145 MB on 2026-11-18, so 30 minutes leave about 3 of margin. The
# `testDefaultSettings` shards already take about 27 minutes, so they get a retry only when it is short.
a11y_retry_budget=$((${WESTRON_A11Y_RETRY_BUDGET:-30} * 60))

# How long, in seconds, a retry of <count> entries of <test> would take, judged from the first run in <log>: 90 s to
# start xcodebuild, the simulator and the test runner, then the first run's time per entry it started (150 s, about
# CI's, when the log has no time), at least 30 s.
a11y_retry_estimate() {
  local log="$1" test="$2" count="$3"
  awk -v test="$test" -v count="$count" -v q="'" '
    BEGIN {
      p = "a11y: " test ": started "
      c = "Test Case " q "-[CatalogUITests.CatalogAccessibilityAuditTests " test "]" q " failed ("
    }
    index($0, p) == 1 { started++ }
    index($0, c) { seconds = substr($0, index($0, c) + length(c)) + 0 }
    END {
      per = (started > 0 && seconds > 0) ? seconds / started : 150
      if (per < 30) per = 30
      printf "%d\n", 90 + count * per
    }' "$log"
}

a11y() {
  local platform=ios destination udid="" test name a11y_started=$SECONDS
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
  # The build is a step of its own, so that a build failure fails the audit as one, and the test runs, the first and
  # a retry alike, only on what this build produced.
  local build_log=".build/logs/$name-build.log"
  if ! xcodebuild -project platforms/apple/Catalog/Catalog.xcodeproj -scheme Catalog -destination "$destination" \
    -derivedDataPath .build/xcode/catalog build-for-testing > "$build_log" 2>&1; then
    grep -E "error:|FAILED" "$build_log" | grep -v "\[MT\]" | tail -40 >&2 || true
    echo "check.sh: a11y: the catalog or its UI tests failed to build ($platform), log: $build_log" >&2
    return 1
  fi
  if a11y_run test-without-building "$log" "$results" "$destination" "$udid" "${only[@]}"; then return 0; fi

  # The run failed. On the CI runner the simulator now and then stalls, and XCTest fails what the test asks of it then
  # (#74): an entry the stall hit is audited once more, in a run of its own, and so are the entries a stopped test
  # method did not reach. An entry with a finding is never audited again, and nor is any entry of a test with one, so
  # a finding fails the run however rarely it shows.
  local failed=0 plan entries what retry_name retry_log retry_results elapsed estimate
  local first_entry="${TEST_RUNNER_WESTRON_ENTRY:-}" first_shard="${TEST_RUNNER_WESTRON_ENTRY_SHARD:-}"
  unset TEST_RUNNER_WESTRON_A11Y_FAIL_ONCE
  [ $# -gt 0 ] || set -- "${a11y_tests[@]}"
  for test in "$@"; do
    plan="$(a11y_plan "$log" "$test")"
    case "$plan" in
      pass) continue ;;
      fail*)
        echo "check.sh: a11y: $test failed, not retried: ${plan#fail }" >&2
        failed=1
        continue
        ;;
    esac
    entries="${plan#retry }"
    what="$test for ${entries/#\*/all its entries}"
    # Only if the retry fits the time budget: a leg the timeout kills loses its logs.
    elapsed=$((SECONDS - a11y_started))
    if [ "$entries" = "*" ]; then
      # Nothing was audited, so nothing tells how long the test takes: a whole test is retried only in the first half
      # of the budget. On CI the runner failed at install 7 minutes into the leg; a whole shard takes 13–19 minutes.
      estimate=$((a11y_retry_budget / 2))
    else
      estimate="$(a11y_retry_estimate "$log" "$test" "$(tr ',' '\n' <<< "$entries" | wc -l | tr -d ' ')")"
    fi
    if [ $((elapsed + estimate)) -gt "$a11y_retry_budget" ]; then
      echo "check.sh: a11y: $what failed for infrastructure, not retried: $((elapsed / 60)) min have gone and the" \
        "retry would take about $((estimate / 60)) min more, past the budget of $((a11y_retry_budget / 60)) min" \
        "(WESTRON_A11Y_RETRY_BUDGET)" >&2
      failed=1
      continue
    fi
    echo "a11y: retrying $what: the first run failed for infrastructure; its failures are above (log: $log)"
    if [ -n "${GITHUB_ACTIONS:-}" ]; then
      echo "::warning title=Accessibility audit retried::$what: the first run failed for infrastructure. Its" \
        "failures are in this step's output; its log is uploaded as the a11y-retried-… artifact."
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
