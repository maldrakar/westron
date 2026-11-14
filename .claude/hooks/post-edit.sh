#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit): форматирует отредактированный Swift-файл и проверяет его линтом
# сырых значений, если это код компонентов. Код 2 возвращает агенту нарушения через stderr.
# Нужны Node (он же разбирает входной JSON) и, для формата, Xcode из .xcode-version.
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

# Линт не зависит от Xcode, поэтому идёт первым.
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
  echo "post-edit: Xcode $(cat .xcode-version) не найден — $file не отформатирован; tools/apple/check.sh format поймает это позже" >&2
  exit 0
fi
if ! output="$(swift format format --in-place "$file" 2>&1)"; then
  echo "swift format не смог отформатировать $file:" >&2
  echo "$output" >&2
  exit 2
fi
exit 0
