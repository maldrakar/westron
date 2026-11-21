#!/usr/bin/env bash
# Tests tools/apple/lock.sh, the lock the Apple scripts queue on (#107), with no simulator and no Xcode: on macOS and
# on Linux, where tools/check.sh runs it (step locks). Each case runs scripts that take one lock in a folder of its
# own, under the bash that runs this script, and prints what they said; about 10 s in all.
#
#   tools/apple/lock-test.sh
#
# Cases: two holders at once run one after the other, the second saying whom it waits for; a lock whose holder was
# killed with SIGKILL is taken over at once; a script that holds the lock, and the scripts it runs, take it again
# without waiting; a wait past WESTRON_LOCK_TIMEOUT fails with a message; the lock goes on a normal exit, beside the
# script's own EXIT trap, and on SIGTERM.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/westron-lock-test.XXXXXX")"
export WESTRON_LOCK_DIR="$work/locks" WESTRON_LOCK_TEST_HELPER="$root/tools/apple/lock.sh"
unset WESTRON_LOCK_HOLDERS WESTRON_LOCK_TIMEOUT
lock="$WESTRON_LOCK_DIR/test"
background=()
failures=0

cleanup() {
  local pid
  for pid in ${background[@]+"${background[@]}"}; do kill -9 "$pid" 2> /dev/null || true; done
  rm -rf "$work"
}
trap cleanup EXIT

fail() {
  echo "lock-test: FAIL: $*" >&2
  failures=$((failures + 1))
}
ok() { echo "lock-test: ok: $*"; }

# Prints <file> indented, as what a case's scripts said.
show() { sed 's/^/    /' "$1"; }

# A script run as `"$BASH" -c "$load<script>" <name> <argument>…` is the program <name>, with lock.sh loaded and the
# arguments as $1…. One in the background is started so, not through run, so that $! is its own pid.
load='source "$WESTRON_LOCK_TEST_HELPER"; '
run() {
  local name="$1" script="$2"
  shift 2
  "$BASH" -c "$load$script" "$name" "$@"
}

# Waits until <file> exists, at most 10 s.
wait_for() {
  local tries=0
  until [ -e "$1" ]; do
    tries=$((tries + 1))
    if [ "$tries" -gt 100 ]; then
      fail "$1 did not appear"
      return 1
    fi
    sleep 0.1
  done
}

# The resource is free when its lock is gone (it is a symbolic link, dangling, so -L).
free() { [ ! -L "$lock" ]; }

echo "== two holders at once"
"$BASH" -c "$load"'trap "echo first: its own EXIT trap ran" EXIT
  westron_lock test "the test resource"
  echo "first start" >> "$1"; touch "$1.first"; sleep 2; echo "first end" >> "$1"' first "$work/order" \
  > "$work/first.out" 2> "$work/first.err" &
first=$!
background+=("$first")
wait_for "$work/order.first"
run second 'westron_lock test "the test resource"; echo "second start" >> "$1"; echo "second end" >> "$1"' \
  "$work/order" 2> "$work/second.err"
wait "$first"
show "$work/order"
show "$work/second.err"
if [ "$(tr '\n' ,< "$work/order")" = "first start,first end,second start,second end," ]; then
  ok "the second started after the first ended"
else
  fail "the two ran out of order"
fi
if grep -q "^second: waiting for the test resource: pid $first holds it since .*: .*first" "$work/second.err" \
  && [ "$(grep -c "waiting for" "$work/second.err")" -eq 1 ]; then
  ok "the second said once whom it waited for"
else
  fail "the second did not say once whom it waited for"
fi
show "$work/first.out"
if grep -q "its own EXIT trap ran" "$work/first.out" && free; then
  ok "the first released the lock on exit, and its own EXIT trap ran too"
else
  fail "the first left its lock, or its own EXIT trap did not run"
fi

echo "== a holder killed with SIGKILL"
"$BASH" -c "$load"'westron_lock test "the test resource"; touch "$1"; exec sleep 60' killed "$work/killed.locked" &
killed=$!
background+=("$killed")
wait_for "$work/killed.locked"
kill -9 "$killed"
wait "$killed" 2> /dev/null || true
if free; then fail "the killed holder's lock is gone; nothing to take over"; fi
started=$SECONDS
WESTRON_LOCK_TIMEOUT=5 run successor 'westron_lock test "the test resource" && echo "successor: took it"' \
  > "$work/successor.out" 2> "$work/successor.err" || true
show "$work/successor.err"
show "$work/successor.out"
if grep -q "left by pid $killed, which no longer runs; taking it over" "$work/successor.err" \
  && grep -q "took it" "$work/successor.out" && [ $((SECONDS - started)) -lt 3 ] && free; then
  ok "the lock was taken over in $((SECONDS - started)) s"
else
  fail "the dead holder's lock was not taken over at once"
fi

echo "== nested: a holder, and the scripts it runs"
# The outer script takes the lock twice and runs the inner one, which takes another lock and the outer's, and runs the
# innermost, which takes both. A limit of 0: a wait would fail at once.
cat > "$work/innermost.sh" << 'EOF'
source "$WESTRON_LOCK_TEST_HELPER"
westron_lock test "the test resource" && westron_lock other "another resource" && echo "innermost: took both"
EOF
cat > "$work/inner.sh" << 'EOF'
source "$WESTRON_LOCK_TEST_HELPER"
westron_lock other "another resource" && westron_lock test "the test resource" && echo "inner: took both"
"$BASH" "${0%/*}/innermost.sh"
EOF
WESTRON_LOCK_TIMEOUT=0 run outer 'westron_lock test "the test resource"
  westron_lock test "the test resource" && echo "outer: took it again"
  "$BASH" "$1"' "$work/inner.sh" > "$work/nested.out" 2> "$work/nested.err" || true
show "$work/nested.out"
show "$work/nested.err"
if [ "$(tr '\n' , < "$work/nested.out")" = "outer: took it again,inner: took both,innermost: took both," ] \
  && [ ! -s "$work/nested.err" ] && free && [ ! -L "$WESTRON_LOCK_DIR/other" ]; then
  ok "none of them waited, and both locks went with their holders"
else
  fail "a nested call waited or failed"
fi

echo "== a wait past WESTRON_LOCK_TIMEOUT"
"$BASH" -c "$load"'trap "kill \$sleeper" EXIT; westron_lock test "the test resource"; touch "$1"
  sleep 30 & sleeper=$!; wait' holder "$work/holder.locked" 2> "$work/holder.err" &
holder=$!
background+=("$holder")
wait_for "$work/holder.locked"
status=0
started=$SECONDS
WESTRON_LOCK_TIMEOUT=2 run impatient 'westron_lock test "the test resource" && echo "impatient: took it"' \
  > "$work/impatient.out" 2> "$work/impatient.err" || status=$?
show "$work/impatient.err"
if [ "$status" -ne 0 ] && [ ! -s "$work/impatient.out" ] && [ $((SECONDS - started)) -lt 5 ] \
  && grep -q "^impatient: gave up waiting for the test resource after [23] s (WESTRON_LOCK_TIMEOUT=2): pid $holder" \
    "$work/impatient.err"; then
  ok "it failed with status $status after $((SECONDS - started)) s"
else
  fail "the wait did not end at the limit with a message (status $status)"
fi

echo "== a holder stopped with SIGTERM"
kill -TERM "$holder"
wait "$holder" 2> /dev/null || true
if free; then ok "the lock went with it"; else fail "the lock stayed after SIGTERM"; fi

if [ "$failures" -ne 0 ]; then
  echo "lock-test: $failures failed" >&2
  exit 1
fi
echo "lock-test: all passed"
