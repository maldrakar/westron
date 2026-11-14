#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit): форматирует отредактированный Swift-файл и проверяет его линтом
# сырых значений, если это код компонентов. Код 2 возвращает агенту нарушения через stderr.
set -uo pipefail

root="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
file="$(jq -r '.tool_input.file_path // empty')"
[ -n "$file" ] && [ -f "$file" ] || exit 0
case "$file" in /*) ;; *) file="$root/$file" ;; esac
case "$file" in "$root"/*) ;; *) exit 0 ;; esac
case "$file" in *.swift) ;; *) exit 0 ;; esac

cd "$root" || exit 0
# shellcheck source=tools/apple/xcode-env.sh
source tools/apple/xcode-env.sh 2>/dev/null || exit 0

if ! output="$(swift format format --in-place "$file" 2>&1)"; then
  echo "swift format не смог отформатировать $file:" >&2
  echo "$output" >&2
  exit 2
fi

case "$file" in
  "$root"/platforms/apple/Sources/WestronUI/*)
    if ! output="$(node tools/lint/raw-values.ts "$file" 2>&1)"; then
      echo "$output" >&2
      exit 2
    fi
    ;;
esac
exit 0
