# shellcheck shell=bash
# Loaded with `source`: a machine-wide lock on what only one run at a time can use (#107). Several agents work on one
# Mac, each in a worktree of its own, and two test runs on one iOS simulator fail or stall each other, as a macOS UI
# test captures whatever window is on top. The scripts that use one take its lock first and queue:
#
#   westron_lock_simulator "$udid" || exit 1   # the iOS simulator <udid>, for a test run on it
#   westron_lock_screen || exit 1              # the Mac's screen, for a UI test on macOS
#
# hold it until the script exits (westron_lock). A script that finds the lock held prints once who holds it (pid,
# command, since when) and waits, at most WESTRON_LOCK_TIMEOUT seconds (default 5400, 90 minutes), then fails with a
# message. A lock whose process no longer runs is taken over. A script that holds a lock, and the scripts it runs, take
# it again at once: the holders' pids are exported in WESTRON_LOCK_HOLDERS. Plain bash 3.2 with POSIX tools, so that
# tools/apple/lock-test.sh runs on Linux too (tools/check.sh, step locks).

# Where the locks are: WESTRON_LOCK_DIR (the test sets it), else on macOS the user's temporary folder that the system
# gives every process of the user, asked of getconf rather than read from $TMPDIR, which a sandbox or a session can
# point elsewhere: every worktree and every session of the user then meets the same locks, outside any checkout, and
# other users have their own. Elsewhere a folder of the user's in $TMPDIR or /tmp.
westron_lock_dir() {
  local dir
  if [ -n "${WESTRON_LOCK_DIR:-}" ]; then
    dir="$WESTRON_LOCK_DIR"
  elif dir="$(getconf DARWIN_USER_TEMP_DIR 2> /dev/null)" && [ -n "$dir" ]; then
    dir="${dir%/}/westron-locks"
  else
    dir="${TMPDIR:-/tmp}"
    dir="${dir%/}/westron-locks-$(id -u)"
  fi
  mkdir -p "$dir" || return 1
  echo "$dir"
}

# Prints when process <pid> started, with no spaces, or `-` when ps cannot tell (a container without ps): with the pid
# it tells the holder from a later process that got the same pid. In the C locale and UTC: ps writes the time in the
# caller's locale and time zone, and a waiter started from another terminal must read the holder's time as it wrote it.
westron_lock_started() {
  local started
  started="$(LC_ALL=C TZ=UTC0 ps -o lstart= -p "$1" 2> /dev/null | tr -d ' ')" || true
  echo "${started:--}"
}

# Whether the holder a lock names, `<pid> <since> <started> <command>`, still runs: its pid is alive, not a zombie, and
# started when it did.
westron_lock_alive() {
  local pid since started command
  read -r pid since started command <<< "$1"
  kill -0 "$pid" 2> /dev/null || return 1
  case "$(ps -o stat= -p "$pid" 2> /dev/null)" in Z*) return 1 ;; esac
  [ "$started" = - ] || [ "$(westron_lock_started "$pid")" = "$started" ]
}

# Prints <epoch seconds> as the time of day (BSD date, then GNU date).
westron_lock_time() {
  date -r "$1" +%H:%M:%S 2> /dev/null || date -d "@$1" +%H:%M:%S 2> /dev/null || echo "$1"
}

# Removes the lock <path> left by the dead holder <target>, unless another process has already done so and taken it
# (the lock names someone else by then). The takeover is itself guarded, by a directory, so that of two waiters that
# both found the holder dead the second does not remove the lock the first has just taken; a guard older than a minute
# was left by a process that died between its two steps.
westron_lock_take_over() {
  local lock="$1" target="$2" guard="$1.takeover"
  if mkdir "$guard" 2> /dev/null; then
    [ "$(readlink "$lock" 2> /dev/null)" != "$target" ] || rm -f "$lock"
    rmdir "$guard"
  elif [ -n "$(find "$guard" -maxdepth 0 -mmin +1 2> /dev/null)" ]; then
    rmdir "$guard" 2> /dev/null || true
  else
    sleep 1
  fi
}

# Releases the lock <key> before the script exits, when it holds it itself (not when a script that ran it does): for a
# target that is done with the resource while the script goes on, as `check.sh all` after package-ios.
westron_unlock() {
  local lock
  lock="$(westron_lock_dir)/$1" || return 1
  [ "$(readlink "$lock" 2> /dev/null | cut -d ' ' -f 1)" != "$$" ] || rm -f "$lock"
}

# Removes the locks this script took (westron_lock), on its exit.
westron_lock_release() {
  local lock
  for lock in ${westron_locks_taken[@]+"${westron_locks_taken[@]}"}; do
    [ "$(readlink "$lock" 2> /dev/null | cut -d ' ' -f 1)" != "$$" ] || rm -f "$lock"
  done
  westron_locks_taken=()
}

# Takes the lock <key> on <what> (named in the messages) for the rest of the script, waiting while another process
# holds it. The lock is a symbolic link whose target names the holder: creating one is atomic, so of two scripts that
# start together one gets it, and it is read in one call. It goes on the script's exit, normal or failed, and on
# SIGTERM or an INT the script traps: an EXIT trap, added to the one the script has (one set after this would replace
# it). Where nothing runs that trap, the lock stays behind its dead holder and the next script takes it over at once:
# a process killed with SIGKILL, and Ctrl-C while bash 3.2 waits for a foreground command, of which it dies without
# running the EXIT trap.
westron_lock() {
  local key="$1" what="$2" name="${0##*/}" limit="${WESTRON_LOCK_TIMEOUT:-5400}" dir lock mine target pid since
  local command process_started started=$SECONDS waited="" trap_exit error vanished=0
  if ! [[ "$limit" =~ ^[0-9]+$ ]]; then
    echo "$name: WESTRON_LOCK_TIMEOUT=\"$limit\": expected whole seconds" >&2
    return 2
  fi
  dir="$(westron_lock_dir)" || return 1
  lock="$dir/$key"
  command="$(ps -o command= -p $$ 2> /dev/null)" || true
  command="${command:-$0}"
  mine="$$ $(date +%s) $(westron_lock_started $$) ${command:0:400} (in $PWD)"
  while :; do
    if error="$(ln -sn "$mine" "$lock" 2>&1)"; then
      westron_locks_taken+=("$lock")
      export WESTRON_LOCK_HOLDERS="${WESTRON_LOCK_HOLDERS:+$WESTRON_LOCK_HOLDERS }$$"
      if [ "${westron_lock_trapped:-}" != "$$" ]; then
        trap_exit="$(trap -p EXIT)"
        if [ -n "$trap_exit" ]; then
          eval "set -- $trap_exit"
          trap "$3"'
westron_lock_release' EXIT
        else
          trap westron_lock_release EXIT
        fi
        westron_lock_trapped=$$
      fi
      if [ -n "$waited" ]; then
        echo "$name: took the lock on $what after $((SECONDS - started)) s of waiting" >&2
      fi
      return 0
    fi
    # No lock to read: its holder has just released it, between the two calls, and the next try takes it; when that
    # happens three times running, ln fails for another reason (a folder it cannot write to).
    if ! target="$(readlink "$lock" 2> /dev/null)"; then
      vanished=$((vanished + 1))
      if [ "$vanished" -ge 3 ]; then
        echo "$name: cannot take the lock on $what: $error" >&2
        return 1
      fi
      continue
    fi
    vanished=0
    pid="${target%% *}"
    if ! westron_lock_alive "$target"; then
      echo "$name: the lock on $what was left by pid $pid, which no longer runs; taking it over" >&2
      westron_lock_take_over "$lock" "$target"
      continue
    fi
    # This script holds it already, or the script that ran this one does.
    [[ " ${WESTRON_LOCK_HOLDERS:-} " != *" $pid "* ]] || return 0
    if [ $((SECONDS - started)) -ge "$limit" ]; then
      echo "$name: gave up waiting for $what after $((SECONDS - started)) s (WESTRON_LOCK_TIMEOUT=$limit): pid" \
        "$pid still holds it: ${target#* * * }" >&2
      return 1
    fi
    if [ "$target" != "$waited" ]; then
      read -r pid since process_started command <<< "$target"
      echo "$name: waiting for $what: pid $pid holds it since $(westron_lock_time "$since"): $command" \
        "(at most $limit s, WESTRON_LOCK_TIMEOUT)" >&2
      waited="$target"
    fi
    sleep 1
  done
}

westron_lock_simulator() { westron_lock "simulator-$1" "the iOS simulator $1"; }

westron_lock_screen() { westron_lock screen "the Mac's screen"; }
