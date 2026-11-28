#!/usr/bin/env bash
# Checks for the Swift part of westron. CI runs the checks of `all`, and a11y and behavior in jobs of their own; the
# agent's Stop hook runs format, package, platforms and catalog, each only when the changes touch what it checks.
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
#   tools/apple/check.sh behavior [ios|macos] [class …]
#                                    the catalog's behaviour UI tests (default: the iOS simulator), the classes named
#                                    (ButtonBehaviorTests CheckboxBehaviorTests TextFieldBehaviorTests
#                                    TextFieldAccessibilityFrameTests IconAccessibilityTests IconTileAccessibilityTests
#                                    ChipBehaviorTests ListRowBehaviorTests DisclosureBehaviorTests ChoiceListSheetTests
#                                    EmptyStateTests FormTests; default: all); a run that stops making progress
#                                    (WESTRON_BEHAVIOR_STALL_LIMIT=<seconds>, default 300) or fails for infrastructure
#                                    runs once more what has not passed, never a test XCTest reported a failure of its
#                                    own for (#97); WESTRON_BEHAVIOR_DEADLINE=<minutes> stops it all at that time
#   tools/apple/check.sh format      swift format lint without changes, tools/ included
#   tools/apple/check.sh fix-format  swift format that rewrites the files, tools/ included
#   tools/apple/check.sh all         everything except fix-format, a11y and behavior (package-ios included)
#
# package-ios, a11y and behavior queue for the iOS simulator, and on macOS for the Mac's screen, while another run
# anywhere on this Mac uses it: they say whom they wait for and wait, at most WESTRON_LOCK_TIMEOUT seconds (default
# 5400; tools/apple/lock.sh).
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
# shellcheck source=tools/apple/xcode-env.sh
source tools/apple/xcode-env.sh
# shellcheck source=tools/apple/lock.sh
source tools/apple/lock.sh

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
  westron_lock_simulator "$udid" || return 1
  # Without -collect-test-diagnostics never, a failed run waits minutes for a sysdiagnose of the simulator.
  xcodebuild -scheme Westron-Package -destination "id=$udid" -derivedDataPath .build/xcode/package \
    -collect-test-diagnostics never test > "$log" 2>&1 || status=$?
  stop_test_daemon "$udid"
  # Done with the simulator: `all` goes on to platforms and catalog, which need none.
  westron_unlock "simulator-$udid"
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

# Sets `destination` and `udid` for the catalog's UI tests on <platform>: on iOS the simulator $WESTRON_SIM_DEVICE
# (default iPhone 17), booted if need be; on macOS the Mac, with an empty udid.
ui_test_destination() {
  udid=""
  case "$1" in
    ios)
      # shellcheck source=tools/apple/simulator.sh
      source tools/apple/simulator.sh
      udid="$(westron_simulator_udid "${WESTRON_SIM_DEVICE:-iPhone 17}")" || return 1
      destination="id=$udid"
      ;;
    macos) destination="platform=macOS,arch=$(uname -m)" ;;
  esac
}

# Builds the catalog and its UI tests for <destination> into <build log>, a step of its own, so that a build failure
# fails the run as one, and every test run uses what this build produced. <what> and <platform> name the run in the
# message.
ui_test_build() {
  local destination="$1" build_log="$2" what="$3" platform="$4"
  if ! xcodebuild -project platforms/apple/Catalog/Catalog.xcodeproj -scheme Catalog -destination "$destination" \
    -derivedDataPath .build/xcode/catalog build-for-testing > "$build_log" 2>&1; then
    grep -E "error:|FAILED" "$build_log" | grep -v "\[MT\]" | tail -40 >&2 || true
    echo "check.sh: $what: the catalog or its UI tests failed to build ($platform), log: $build_log" >&2
    return 1
  fi
}

# Takes the lock of the UI tests' destination (tools/apple/lock.sh), the simulator <udid> or, with an empty one, the
# Mac's screen, after the build, which needs neither, and before behavior's watchdog starts, which a wait would trip.
# Sets ui_test_waited to the seconds it waited: a11y moves the start of its retry budget by them. behavior's
# WESTRON_BEHAVIOR_DEADLINE still counts the wait; only CI sets it, and nothing waits there.
ui_test_lock() {
  local before=$SECONDS
  if [ -n "$1" ]; then westron_lock_simulator "$1"; else westron_lock_screen; fi || return 1
  ui_test_waited=$((SECONDS - before))
}

# An interrupted UI test run: stops its xcodebuild and the simulator's test daemon, then exits with <status>. The
# `|| true`: under `set -e`, the wait for the killed xcodebuild (status 143) would end the script before the daemon is
# stopped.
ui_test_interrupted() {
  local udid="$1" status="$2"
  kill "$ui_test_xcodebuild" 2> /dev/null || true
  wait "$ui_test_xcodebuild" 2> /dev/null || true
  stop_test_daemon "$udid"
  exit "$status"
}

# Runs xcodebuild <action> on the catalog's UI tests into <log> and <results> on <destination>, with the -only-testing
# arguments after them, and returns xcodebuild's status. Without -collect-test-diagnostics never, a failed run waits
# minutes for a sysdiagnose of the simulator. xcodebuild runs in the background and the script waits for it, so that
# an interruption reaches the traps at once; however the run ends, the simulator's test daemon is stopped
# (stop_test_daemon), and an interruption exits with the shell's status for its signal, 130 for INT and 143 for TERM.
ui_test_run() {
  local action="$1" log="$2" results="$3" destination="$4" udid="$5" status=0
  shift 5
  rm -rf "$results"
  xcodebuild -project platforms/apple/Catalog/Catalog.xcodeproj -scheme Catalog -destination "$destination" \
    -derivedDataPath .build/xcode/catalog -resultBundlePath "$results" -collect-test-diagnostics never \
    "$@" "$action" > "$log" 2>&1 &
  ui_test_xcodebuild=$!
  trap 'ui_test_interrupted "$udid" 130' INT
  trap 'ui_test_interrupted "$udid" 143' TERM
  wait "$ui_test_xcodebuild" || status=$?
  trap - INT TERM
  stop_test_daemon "$udid"
  return "$status"
}

# xcodebuild's lines for a test runner that did not start (a11y_plan), printed with a run's output.
a11y_runner_failures="Failed to install or launch the test runner|Early unexpected exit"

# Runs the audit (ui_test_run, same arguments); prints what the run reported and returns xcodebuild's status.
a11y_run() {
  local log="$2" status=0
  ui_test_run "$@" || status=$?
  # The issues the audit found, suppressed and deferred, each failure with its kind, then the test cases and the
  # totals, and why a test runner did not start (a11y_plan). The test's lines of which entry starts and finishes are
  # for a11y_plan alone.
  grep -E "^a11y: |: error: |Test Case .*(passed|failed)|Executed [0-9]+ test|$a11y_runner_failures" "$log" \
    | grep -v "\[MT\]" \
    | grep -vE "^a11y: test[A-Za-z]+: (entries|started|finished) " || true
  return "$status"
}

# What a failed run of the audit test <test> leaves to do, from <log>. Prints one line:
#   pass            the test passed;
#   retry <ids>     the entries to audit once more: the ones the run did not finish, or that failed for infrastructure
#                   alone. Only after a run whose test started (it printed its `entries` line) and whose every failure
#                   the test classified: XCTest's own `error: -[… <test>]` lines are counted against the test's
#                   `failure …` lines, so a lost line cannot turn a finding into an unfinished entry;
#   retry *         all of the test's entries: the test runner failed to start, so nothing was audited. Told by
#                   xcodebuild's message, with no failure of the test and no `entries` line: "Failed to install or
#                   launch the test runner" (seen once on CI, "Mach error -308 - (ipc/mig) server died"), or "Early
#                   unexpected exit, operation never finished bootstrapping" (CI run 44444325775,
#                   testAccessibilityDynamicType 2/4: "The test runner crashed while preparing to run tests:
#                   CatalogUITests-Runner at -[XCTWaiter(StallHandling) handleStalledWait:]", 3.5 minutes after
#                   "Running tests...", with no test case started);
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
    index($0, "Failed to install or launch the test runner") { runner = 1 }
    index($0, "Early unexpected exit, operation never finished bootstrapping") { runner = 1 }
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
        if (runner && classified == 0 && errors == 0) print "retry *"
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
# at 45 minutes, and a leg killed by the timeout uploads no logs; before the step come about 10 s of setup and
# checkout, after it 15–65 s of output and upload, so 40 minutes leave about 3–4 of margin. On CI (runs 44315755921
# and 44339047592, 2026-11-18, 17 legs) the step spends 6.5–17.1 minutes, median 10.0 and mean 10.4, before the
# first entry (finding the simulator, the build, starting the test runner; the end of the first test run less the
# test's own time), and a stall fails its entry 2–3 minutes in. The worst usual case, a stall in the first entry of
# the slowest leg after the mean 10.4 minutes, fits: with the legs of phase 3 (28 entries),
# a contrast test's single leg, 10.4 + 3 + 90 s + 28 × 38 s = 32.6 minutes (a11y_retry_estimate below). When the
# step needed more than about 17.8 minutes before the first entry it does not, and the leg fails rather than run into
# the timeout. (Before phase 3: legs of 35 minutes, a budget of 30, `testDefaultSettings` 1/2 with 9 entries, 28.4.)
# These are the legs of the nightly full audit (.github/workflows/accessibility-audit.yml). A pull request's audit of
# the entries it changes, all five tests in one leg of at most 5 entries, times out at 55 minutes and sets a budget of
# 50 (.github/workflows/ci.yml has its arithmetic).
a11y_retry_budget=$((${WESTRON_A11Y_RETRY_BUDGET:-40} * 60))

# How long, in seconds, a retry of <count> entries of <test> would take, judged from the first run in <log>: 90 s to
# start xcodebuild and the test runner on the booted simulator (a retry on CI took 38 s, 2026-11-18), then for each
# entry the mean time of the entries of <test> the first run finished cleanly, at least 30 s. An entry's time runs
# from the first of XCTest's activity times (`t = <s>s`, from the start of the test method) after its `started` line
# to the first after its `finished` line. An entry with a failure, or whose audit the test retried on the spot (-56),
# is left out: a stall's minutes say nothing about how long a page takes. When no entry finished cleanly, or the log
# has no activity times, the time per entry is the slowest leg's mean on CI for the test (the test's time in its
# `Test Case … passed` line over the leg's entries; of the same 17 legs, the 15 that passed on their first run:
# 4 of testDefaultSettings, 5 of testAccessibilityDynamicType, 6 of the other three) with a margin of about 12–15 %:
# testDefaultSettings 60–81 s → 90, testAccessibilityDynamicType 50–114 s → 130, the other three 25–33 s → 38.
a11y_retry_estimate() {
  local log="$1" test="$2" count="$3" fallback
  case "$test" in
    testDefaultSettings) fallback=90 ;;
    testAccessibilityDynamicType) fallback=130 ;;
    *) fallback=38 ;;
  esac
  awk -v test="$test" -v count="$count" -v fallback="$fallback" '
    function after(prefix) { return substr($0, length(prefix) + 1) }
    BEGIN { p = "a11y: " test ": " }
    match($0, /^ +t = +[0-9.]+s /) {
      t = substr($0, RSTART, RLENGTH)
      sub(/^ +t = +/, "", t)
      t += 0
      if (opening != "") { start[opening] = t; opening = "" }
      if (closing != "") { if (closing in start) took[closing] = t - start[closing]; closing = "" }
    }
    index($0, p "started ") == 1 { current = opening = after(p "started ") }
    index($0, p "finished ") == 1 { closing = after(p "finished "); current = "" }
    index($0, p "failure in ") == 1 { rest = after(p "failure in "); slow[substr(rest, 1, index(rest, " (") - 1)] = 1 }
    index($0, "a11y: retrying the audit of ") == 1 && current != "" { slow[current] = 1 }
    END {
      for (entry in took) if (!(entry in slow)) { finished++; seconds += took[entry] }
      per = finished > 0 ? seconds / finished : fallback
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
  ui_test_destination "$platform" || return 1
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
  # The test runs, the first and a retry alike, use only what this build produced.
  ui_test_build "$destination" ".build/logs/$name-build.log" "a11y" "$platform" || return 1
  ui_test_lock "$udid" || return 1
  # The retry's budget counts from the start without the wait: on CI nothing waits.
  a11y_started=$((a11y_started + ui_test_waited))
  local first_status=0
  a11y_run test-without-building "$log" "$results" "$destination" "$udid" "${only[@]}" || first_status=$?
  [ "$first_status" -ne 0 ] || return 0

  # The run failed. On the CI runner the simulator now and then stalls, and XCTest fails what the test asks of it then
  # (#74): an entry the stall hit is audited once more, in a run of its own, and so are the entries a stopped test
  # method did not reach. An entry with a finding is never audited again, and nor is any entry of a test with one, so
  # a finding fails the run however rarely it shows.
  local failed=0 retried=0 plan entries what retry_name retry_log retry_results elapsed estimate
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
      # of the budget, 20 minutes. On CI the runner failed at install 7 minutes into the leg, and crashed while
      # bootstrapping 12 (run 44444325775); a whole leg of phase 3 takes 15–18 minutes of tests.
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
      ui_test_lock "$udid" || return 1
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
    retried=1
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
  # Every test passed, yet xcodebuild failed: the runner died or the result bundle was not written after the last test.
  if [ "$retried" -eq 0 ]; then
    echo "check.sh: a11y: xcodebuild exited with status $first_status although every test passed ($platform)," \
      "log: $log, result: $results" >&2
    return 1
  fi
  echo "a11y: passed after a retry; the first run's log: $log"
}

# The catalog's behaviour UI tests (platforms/apple/README.md, "Behaviour UI tests"): presses, hit areas, the
# accessibility hierarchy, the keyboard, on the catalog's entries. Each class runs on iOS and macOS, with branches of
# its own for each; macOS needs Automation Mode and the screen to itself. A run that fails for infrastructure (it
# stopped making progress, its test runner did not start, XCTest failed to terminate the catalog) runs once more, in a
# second xcodebuild run, what has not passed (#97): a test that never finished runs again, but a test with a failure
# of its own (behavior_plan) is never retried, and the nightly CI run reports it
# (.github/workflows/accessibility-audit.yml).
behavior_tests=(ButtonBehaviorTests CheckboxBehaviorTests TextFieldBehaviorTests TextFieldAccessibilityFrameTests
  IconAccessibilityTests IconTileAccessibilityTests ChipBehaviorTests ListRowBehaviorTests DisclosureBehaviorTests
  ChoiceListSheetTests EmptyStateTests FormTests)

# WESTRON_BEHAVIOR_DEADLINE=<minutes> from the script's start (unset: none; CI sets it a few minutes before the job's
# timeout, since a job the timeout kills uploads no logs, and a macOS UI test run has gone silent on CI for an hour,
# run 44461921450): at it, the timer below stops the run's xcodebuild and signals the script (USR1), which says so in
# its output and the log, stops the test daemon and exits 1. It bounds a retry too. The timer ends with the script;
# bash 3.2 has no BASHPID, so it polls the script's pid rather than being waited for.
behavior_deadline_timer() {
  local deadline="$1"
  while kill -0 $$ 2> /dev/null; do
    if [ "$SECONDS" -ge "$deadline" ]; then
      kill -USR1 $$ 2> /dev/null || return 0
      pkill -P $$ -x xcodebuild 2> /dev/null || true
      return 0
    fi
    sleep 1
  done
}

# On macOS the test runner and the catalog belong to launchd, not to xcodebuild: after a run that was stopped, they
# are stopped by their path.
behavior_stop_macos_apps() {
  if [ "$behavior_platform" = macos ]; then
    pkill -f "$root/.build/xcode/catalog/Build/Products/" 2> /dev/null || true
  fi
}

# The script's side of the deadline. A foreground build ends first (the timer stopped it), a test run's wait at once.
behavior_at_deadline() {
  local why="stopped at the deadline: $((SECONDS / 60)) min $((SECONDS % 60)) s since the start"
  why+=" (WESTRON_BEHAVIOR_DEADLINE=$WESTRON_BEHAVIOR_DEADLINE)"
  # xcodebuild first: it writes the log at its own offset, over a line appended before it ends.
  if [ -n "${ui_test_xcodebuild:-}" ]; then
    kill "$ui_test_xcodebuild" 2> /dev/null || true
    wait "$ui_test_xcodebuild" 2> /dev/null || true
  fi
  pkill -P $$ -x xcodebuild 2> /dev/null || true
  echo "check.sh: behavior: $why, so that the logs upload before the job's timeout; log: $behavior_log" >&2
  printf '\ncheck.sh: behavior: %s\n' "$why" >> "$behavior_log"
  behavior_stop_macos_apps
  stop_test_daemon "$behavior_udid"
  exit 1
}

# WESTRON_BEHAVIOR_STALL_LIMIT=<seconds> (default 300): a test run whose log gains no line for this long, xcodebuild's
# own `[MT]` messages aside, has stopped making progress and is stopped (#97). On CI (run 44863177076, iOS) XCTest
# failed to terminate the catalog ("Failed to terminate dev.westron.catalog", 69 s after it began to try), then
# xcodebuild wrote nothing for 28 minutes, until the deadline. A run that works never comes near the limit: XCTest
# writes a line for each step of a test (an activity, `t = …s`): the longest gap between two of them was 4.8 s in that
# run's tests that passed and 1.4 s locally (22 tests, 2026-11-21, where the log, read every second, never went 5 s
# without a line), and starting the test runner took about 20 s on CI. The longest silences XCTest makes on its own
# end in a timeout of its own: the 69 s of that termination, or a test runner that started no test case for 3.5
# minutes on CI before it crashed and xcodebuild reported it (a11y_plan). Five minutes is
# above all of them with room for a runner 2–3 times slower than a local Mac, and a stall then costs 5 minutes of the
# leg rather than all of it, with time left for the retry.
behavior_stall_limit="${WESTRON_BEHAVIOR_STALL_LIMIT:-300}"

# Watches <log> while a test run writes it: every 5 s it counts the log's lines other than xcodebuild's `[MT]` ones,
# and when the count has not changed for <limit> seconds, writes those seconds to <flag> and stops the run's
# xcodebuild, which ends ui_test_run's wait. Started in the background around one test run and killed after it; like
# the deadline timer it polls the script's pid, so that it ends with the script.
behavior_watchdog() {
  local log="$1" limit="$2" flag="$3" lines count=none since=$SECONDS
  while kill -0 $$ 2> /dev/null; do
    lines="$(grep -vc "\[MT\]" "$log" 2> /dev/null || true)"
    if [ "$lines" != "$count" ]; then
      count="$lines" since=$SECONDS
    elif [ $((SECONDS - since)) -ge "$limit" ]; then
      echo "$((SECONDS - since))" > "$flag"
      pkill -P $$ -x xcodebuild 2> /dev/null || true
      return 0
    fi
    sleep 5
  done
}

# Removes the watchdog's flag file of the current test run, if there is one. `behavior` runs it on the script's exit
# too, so that a run the deadline or an interruption (ui_test_interrupted) ends leaves no file behind.
behavior_remove_stall_flag() {
  if [ -n "${behavior_stall_flag:-}" ]; then
    rm -f "$behavior_stall_flag"
    behavior_stall_flag=""
  fi
}

# Runs the behaviour tests, ui_test_run's arguments, under the watchdog, and prints what the run reported: each
# failure with its message, each skip with its reason, the test cases, the totals of each class and of the run, and
# why a test runner did not start. Returns xcodebuild's status; `behavior_stalled` is the seconds of silence after
# which the watchdog stopped the run, or empty.
behavior_run() {
  local log="$2" watchdog status=0
  behavior_stall_flag="$(mktemp "${TMPDIR:-/tmp}/westron-behavior-stall.XXXXXX")"
  behavior_log="$log"
  behavior_watchdog "$log" "$behavior_stall_limit" "$behavior_stall_flag" &
  watchdog=$!
  ui_test_run "$@" || status=$?
  kill "$watchdog" 2> /dev/null || true
  wait "$watchdog" 2> /dev/null || true
  behavior_stalled="$(cat "$behavior_stall_flag")"
  behavior_remove_stall_flag
  grep -E ": error: |Test skipped|Test Case .*(passed|failed|skipped)|Executed [0-9]+ test|$a11y_runner_failures" \
    "$log" | grep -v "\[MT\]" || true
  if [ -n "$behavior_stalled" ]; then
    local why="stopped the run: its log showed no progress for $behavior_stalled s"
    why+=" (WESTRON_BEHAVIOR_STALL_LIMIT=$behavior_stall_limit)"
    echo "check.sh: behavior: $why; log: $log" >&2
    printf '\ncheck.sh: behavior: %s\n' "$why" >> "$log"
    behavior_stop_macos_apps
  fi
  return "$status"
}

# What a failed run in <log> leaves to do; <stalled> is non-empty when the watchdog stopped it. Prints one line:
#   retry [<test>,…]  run once more every test of the selection but these, the ones that passed or skipped
#                     themselves (Class/method). Only when no test failed on its own and something infrastructural
#                     explains the failure: the run stalled (the test it hit had not finished, and is retried, as an
#                     audit entry a stall hit is), the test runner failed to start (a11y_runner_failures), or a test's
#                     every failure is XCTest's "Failed to terminate" of the catalog, which preceded the stall on CI
#                     (run 44863177076) and which the audit classifies as infrastructure;
#   fail <reason>     anything else: a test that failed on its own, that is one with an error line of its own other
#                     than "Failed to terminate" (an assertion, a crash XCTest attributes to it) or a `Test Case …
#                     failed` line with no such error, or a failure nothing explains, such as a stall after every
#                     test had finished.
# Only those two kinds of line tell a test's failure. A test that never finished, because the run stalled or the test
# runner died under it and xcodebuild reported that with neither line for the test, is run again when the run is
# retried, as the audit does for an entry it did not finish.
behavior_plan() {
  local log="$1" stalled="$2"
  awk -v stalled="$stalled" -v runner_failures="$a11y_runner_failures" '
    # "Class/method" from "-[CatalogUITests.Class method]" in the line.
    function test_name(  rest) {
      rest = substr($0, index($0, "-[CatalogUITests.") + 17)
      rest = substr(rest, 1, index(rest, "]") - 1)
      sub(/ /, "/", rest)
      return rest
    }
    /\[MT\]/ { next }
    /^Test Case .* (passed|skipped) \(/ { done[test_name()] = 1; next }
    /^Test Case .* failed \(/ { failed[test_name()] = 1; next }
    /: error: -\[CatalogUITests\./ {
      if (index($0, "] : Failed to terminate ")) infrastructure[test_name()] = 1
      else own[test_name()] = 1
      next
    }
    $0 ~ runner_failures { runner = 1 }
    /^Test Suite .Selected tests. (passed|failed) at / { finished = 1 }
    END {
      for (t in failed) if (!(t in infrastructure)) own[t] = 1
      for (t in own) list = list (list == "" ? "" : ", ") t
      if (list != "") { print "fail a test failed on its own: " list; exit }
      for (t in infrastructure) retried = 1
      if (finished && !retried) {
        print (stalled != "" ? "fail every test had finished when the run stalled" \
          : "fail every test finished, and no failure of a test explains it")
        exit
      }
      if (stalled == "" && !runner && !retried) { print "fail no failure of a test explains it"; exit }
      for (t in done) skip = skip (skip == "" ? "" : ",") t
      print "retry " skip
    }' "$log"
}

# How long, in seconds, a retry of <count> tests would take, judged from the first run in <log>: 90 s to start
# xcodebuild and the test runner, as for the audit (a11y_retry_estimate), then for each test the mean time of the tests
# the first run finished with a margin of 25 %, or 30 s when none finished (on CI, run 44863177076, iOS, the six that
# finished took 8.7–24.7 s, mean 15.7).
behavior_retry_estimate() {
  local log="$1" count="$2"
  awk -v count="$count" '
    /^Test Case .* (passed|skipped) \(/ && match($0, /\(([0-9.]+) seconds\)/) {
      finished++
      seconds += substr($0, RSTART + 1, RLENGTH - 10)
    }
    END {
      per = finished > 0 ? seconds / finished * 1.25 : 30
      printf "%d\n", 90 + count * per
    }' "$log"
}

behavior() {
  local platform=ios destination udid="" test status=0
  case "${1:-}" in ios | macos) platform="$1"; shift ;; esac
  local only=() selection=""
  for test in "$@"; do
    if [[ " ${behavior_tests[*]} " != *" $test "* ]]; then
      echo "check.sh: behavior: no test class \"$test\"; the classes: ${behavior_tests[*]}" >&2
      return 2
    fi
    only+=("-only-testing:CatalogUITests/$test")
    selection+="-$test"
  done
  [ $# -gt 0 ] || set -- "${behavior_tests[@]}"
  if [ ${#only[@]} -eq 0 ]; then
    for test in "$@"; do only+=("-only-testing:CatalogUITests/$test"); done
  fi
  if ! [[ "$behavior_stall_limit" =~ ^[1-9][0-9]*$ ]]; then
    echo "check.sh: behavior: WESTRON_BEHAVIOR_STALL_LIMIT=\"$behavior_stall_limit\": expected whole seconds" >&2
    return 2
  fi
  local name="behavior-$platform$selection"
  local log=".build/logs/$name.log" results=".build/xcode/results/$name.xcresult"
  mkdir -p .build/logs .build/xcode/results
  # An earlier run's retry would pass for this one's (CI uploads the logs when there is a retry's).
  rm -rf ".build/logs/$name-retry.log" ".build/xcode/results/$name-retry.xcresult"
  behavior_log="$log" behavior_platform="$platform" behavior_udid="" behavior_stall_flag=""
  trap behavior_remove_stall_flag EXIT
  if [ -n "${WESTRON_BEHAVIOR_DEADLINE:-}" ]; then
    if ! [[ "$WESTRON_BEHAVIOR_DEADLINE" =~ ^[1-9][0-9]*$ ]]; then
      echo "check.sh: behavior: WESTRON_BEHAVIOR_DEADLINE=\"$WESTRON_BEHAVIOR_DEADLINE\": expected whole minutes" >&2
      return 2
    fi
    : > "$log"
    trap behavior_at_deadline USR1
    behavior_deadline_timer $((WESTRON_BEHAVIOR_DEADLINE * 60)) &
  fi
  ui_test_destination "$platform" || return 1
  behavior_udid="$udid"
  echo "== behavior: $destination${selection:+ (${selection#-})}"
  # The test runs, the first and a retry alike, use only what this build produced.
  ui_test_build "$destination" ".build/logs/$name-build.log" "behavior" "$platform" || return 1
  ui_test_lock "$udid" || return 1
  behavior_run test-without-building "$log" "$results" "$destination" "$udid" "${only[@]}" || status=$?
  [ "$status" -ne 0 ] || return 0

  # The run failed. What has not passed runs once more only when infrastructure explains the failure (behavior_plan).
  local plan skipped skip=() count=0 estimate why retry_log retry_results
  plan="$(behavior_plan "$log" "$behavior_stalled")"
  if [ "${plan%% *}" != retry ]; then
    echo "check.sh: behavior: not retried: ${plan#fail }" >&2
    echo "check.sh: behaviour UI tests failed ($platform), log: $log, result: $results" >&2
    return 1
  fi
  skipped="${plan#retry}"
  skipped="${skipped# }"
  for test in ${skipped//,/ }; do skip+=("-skip-testing:CatalogUITests/$test"); done
  # The tests left, counted in the classes' sources, for the estimate alone: the retry itself names what to skip.
  for test in "$@"; do
    count=$((count + $(grep -cE "^ *func test[A-Za-z0-9_]*\(" "platforms/apple/Catalog/CatalogUITests/$test.swift")))
  done
  count=$((count - ${#skip[@]}))
  [ "$count" -gt 0 ] || count=1
  if [ -n "$behavior_stalled" ]; then
    why="stopped after $behavior_stalled s with no progress"
  elif grep -qE "$a11y_runner_failures" "$log"; then
    why="failed for infrastructure: the test runner did not start"
  else
    why="failed for infrastructure: XCTest failed to terminate the catalog"
  fi
  # Only if the retry can finish before the deadline, when one is set: past it the retry would only be stopped.
  if [ -n "${WESTRON_BEHAVIOR_DEADLINE:-}" ]; then
    estimate="$(behavior_retry_estimate "$log" "$count")"
    if [ $((SECONDS + estimate)) -gt $((WESTRON_BEHAVIOR_DEADLINE * 60)) ]; then
      echo "check.sh: behavior: the run $why, not retried: $((SECONDS / 60)) min $((SECONDS % 60)) s have gone" \
        "and a retry of $count tests would take about $((estimate / 60)) min $((estimate % 60)) s more, past the" \
        "deadline of $WESTRON_BEHAVIOR_DEADLINE min (WESTRON_BEHAVIOR_DEADLINE)" >&2
      echo "check.sh: behaviour UI tests failed ($platform), log: $log, result: $results" >&2
      return 1
    fi
  fi
  echo "behavior: retrying $count tests that have not passed: the first run $why; its output is above (log: $log)"
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    echo "::warning title=Behaviour UI tests retried::$platform: the first run $why, so the $count tests that had" \
      "not passed ran once more. The first run's output is in this step's; its log is uploaded as the" \
      "behavior-retried-$platform artifact."
  fi
  retry_log=".build/logs/$name-retry.log" retry_results=".build/xcode/results/$name-retry.xcresult"
  # The simulator may have died with the run; it is found, and booted again if need be.
  if [ "$platform" = ios ]; then
    udid="$(westron_simulator_udid "${WESTRON_SIM_DEVICE:-iPhone 17}")" || return 1
    destination="id=$udid" behavior_udid="$udid"
    ui_test_lock "$udid" || return 1
  fi
  if ! behavior_run test-without-building "$retry_log" "$retry_results" "$destination" "$udid" "${only[@]}" \
    ${skip[@]+"${skip[@]}"}; then
    echo "check.sh: behavior: failed again on its retry, log: $retry_log, result: $retry_results" >&2
    echo "check.sh: behaviour UI tests failed ($platform), the first run's log: $log, result: $results" >&2
    return 1
  fi
  echo "behavior: passed after a retry; the first run's log: $log"
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
  behavior) shift; behavior "$@" ;;
  format) format ;;
  fix-format) fix_format ;;
  all) format; package; package_ios; platforms; catalog ;;
  *) sed -n '2,/^set -euo pipefail/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
