#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit): formats the edited Swift file and checks it with the raw-values lint
# if it is component code. Exit code 2 returns the violations to the agent through stderr.
# Needs the Xcode from .xcode-version: both the formatter and the lint (tools/westron) run on its Swift.
set -uo pipefail

root="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
file="$(plutil -extract tool_input.file_path raw -o - - 2> /dev/null)"
[ -n "$file" ] || exit 0
case "$file" in /*) ;; *) file="$root/$file" ;; esac
case "$file" in "$root"/*.swift) ;; *) exit 0 ;; esac
[ -f "$file" ] || exit 0
cd "$root" || exit 0

# shellcheck source=tools/apple/xcode-env.sh
if ! source tools/apple/xcode-env.sh 2> /dev/null; then
  echo "post-edit: Xcode $(cat .xcode-version) not found, so $file is neither linted nor formatted;" \
    "tools/check.sh and tools/apple/check.sh format will catch this later" >&2
  exit 0
fi

case "$file" in
  "$root"/platforms/apple/Sources/WestronUI/*)
    if ! output="$(tools/westron lint raw-values "$file" 2>&1)"; then
      echo "$output" >&2
      exit 2
    fi
    ;;
esac

if ! output="$(swift format format --in-place "$file" 2>&1)"; then
  echo "swift format could not format $file:" >&2
  echo "$output" >&2
  exit 2
fi
exit 0
