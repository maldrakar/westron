#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit): formats the edited Swift file and checks it with the raw-values lint
# if it is component code. Exit code 2 returns the violations to the agent through stderr.
# Needs Node (it also parses the input JSON) and, for formatting, Xcode from .xcode-version.
set -uo pipefail

root="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
file="$(node -e '
  let input = "";
  process.stdin.on("data", (chunk) => (input += chunk)).on("end", () => {
    try { process.stdout.write(JSON.parse(input).tool_input?.file_path ?? ""); } catch {}
  });')"
[ -n "$file" ] || exit 0
case "$file" in /*) ;; *) file="$root/$file" ;; esac
case "$file" in "$root"/*.swift) ;; *) exit 0 ;; esac
[ -f "$file" ] || exit 0
cd "$root" || exit 0

# The lint does not depend on Xcode, so it runs first.
case "$file" in
  "$root"/platforms/apple/Sources/WestronUI/*)
    if ! output="$(node tools/lint/raw-values.ts "$file" 2>&1)"; then
      echo "$output" >&2
      exit 2
    fi
    ;;
esac

# shellcheck source=tools/apple/xcode-env.sh
if ! source tools/apple/xcode-env.sh 2> /dev/null; then
  echo "post-edit: Xcode $(cat .xcode-version) not found, so $file is not formatted; tools/apple/check.sh format will catch this later" >&2
  exit 0
fi
if ! output="$(swift format format --in-place "$file" 2>&1)"; then
  echo "swift format could not format $file:" >&2
  echo "$output" >&2
  exit 2
fi
exit 0
