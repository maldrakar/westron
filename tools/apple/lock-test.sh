#!/usr/bin/env bash
# Tests tools/apple/lock.sh, the lock the Apple scripts queue on (#107), with no simulator and no Xcode: on macOS and
# on Linux, where tools/check.sh runs it (step locks). Each case runs scripts that take one lock in a folder of its
# own, under the bash that runs this script, and prints what they said; about 10 s in all.
#
#   tools/apple/lock-test.sh
#
# Cases: two holders at once run one after the other, the second saying whom it waits for; a lock whose holder was
# killed with SIGKILL is taken over at once; a script that holds the lock, and the scripts it runs, take it again
# without waiting; a wait past WESTRON_LOCK_TIMEOUT fails with a message; a waiter in another locale and time zone
# than the holder's waits too, not taking the lock over; the lock goes on a normal exit, beside the script's own EXIT
# trap, on SIGTERM, and on westron_unlock while its script goes on; a lock that cannot be created fails at once with
# ln's message.
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
# The holder in the C locale, three hours west of UTC (a POSIX TZ, which needs no time zone database), for the case
# after this one.
LC_ALL=C TZ=ABC+3 "$BASH" -c "$load"'trap "kill \$sleeper" EXIT; westron_lock test "the test resource"; touch "$1"
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

echo "== a waiter in another locale and time zone than the holder's"
# ps writes a process's start in the caller's locale and time zone; the lock must compare it in fixed ones. Russian if
# the system has it (macOS does; a Linux container may not, and then the time zone alone differs).
# The list is read first: `grep -q` would end `locale -a` early, and pipefail would fail the pipe.
foreign_locale="$(locale -a 2> /dev/null || true)"
foreign_locale="$(grep -ix "ru_RU.utf-\{0,1\}8" <<< "$foreign_locale" | head -1 || true)"
foreign_locale="${foreign_locale:-C}"
status=0
LC_ALL="$foreign_locale" TZ=XYZ-5:45 WESTRON_LOCK_TIMEOUT=1 \
  run foreigner 'westron_lock test "the test resource" && echo "foreigner: took it"' \
  > "$work/foreigner.out" 2> "$work/foreigner.err" || status=$?
show "$work/foreigner.err"
if [ "$status" -ne 0 ] && [ ! -s "$work/foreigner.out" ] && ! grep -q "no longer runs" "$work/foreigner.err" \
  && grep -q "^foreigner: waiting for the test resource: pid $holder" "$work/foreigner.err"; then
  ok "under LC_ALL=$foreign_locale TZ=XYZ-5:45 it waited for the holder in LC_ALL=C TZ=ABC+3"
else
  fail "a waiter in another locale or time zone took the lock of a live holder over (status $status)"
fi

echo "== a holder stopped with SIGTERM"
kill -TERM "$holder"
wait "$holder" 2> /dev/null || true
if free; then ok "the lock went with it"; else fail "the lock stayed after SIGTERM"; fi

echo "== westron_unlock while the script goes on"
run unlocker 'westron_lock test "the test resource"; westron_unlock test
  WESTRON_LOCK_HOLDERS= WESTRON_LOCK_TIMEOUT=0 "$BASH" -c "$1"'"'"'westron_lock test "the test resource" \
    && echo "stranger: took it while the unlocker ran"'"'"' stranger' "$load" > "$work/unlock.out" 2> "$work/unlock.err" \
  || true
show "$work/unlock.out"
show "$work/unlock.err"
if grep -q "stranger: took it" "$work/unlock.out" && [ ! -s "$work/unlock.err" ] && free; then
  ok "another script took the lock at once"
else
  fail "the lock stayed after westron_unlock"
fi

echo "== a lock that cannot be created"
# A name past the longest a file system takes: ln fails with something else than "File exists", for root too (CI runs
# as root in its container, where a folder's mode would not stop it).
long="$(printf 'x%.0s' $(seq 1 300))"
status=0
started=$SECONDS
WESTRON_LOCK_TIMEOUT=2 run unwritable "westron_lock $long \"the long resource\" && echo \"unwritable: took it\"" \
  > "$work/unwritable.out" 2> "$work/unwritable.err" || status=$?
cut -c 1-160 "$work/unwritable.err" | sed 's/^/    /'
if [ "$status" -eq 1 ] && [ ! -s "$work/unwritable.out" ] && [ $((SECONDS - started)) -lt 2 ] \
  && grep -q "^unwritable: cannot take the lock on the long resource: " "$work/unwritable.err"; then
  ok "it failed at once with ln's message"
else
  fail "a lock that cannot be created did not fail at once with a message (status $status)"
fi

if [ "$failures" -ne 0 ]; then
  echo "lock-test: $failures failed" >&2
  exit 1
fi
echo "lock-test: all passed"
