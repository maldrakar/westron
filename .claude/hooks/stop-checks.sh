#!/usr/bin/env bash
# Stop: не даёт агенту закончить работу, пока не пройдут проверки затронутых частей.
#
# Затронутое — незакоммиченные изменения и новые файлы. Успешный результат запоминается по отпечатку
# изменений (.build/agent/), поэтому повторная остановка без новых правок проверки не перезапускает.
# Код 2 возвращает агенту, какая проверка упала, и хвост её вывода.
set -uo pipefail

root="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$root" || exit 0
cat > /dev/null # входной JSON не нужен

changed="$(git status --porcelain --untracked-files=all | cut -c4- | sed 's/.* -> //')"
[ -n "$changed" ] || exit 0

has() { grep -qE "$1" <<< "$changed"; }

checks=()
if has '^(Package\.swift|\.swift-format|\.xcode-version|platforms/apple/|tools/apple/)'; then
  checks+=("tools/apple/check.sh format" "tools/apple/check.sh package")
fi
if has '^platforms/apple/Catalog/'; then
  checks+=("tools/apple/check.sh catalog")
fi
if has '^platforms/apple/Sources/WestronUI/|^tools/lint/'; then
  checks+=("npm run -s lint:raw-values")
fi
if has '^(tools/.*\.ts|package(-lock)?\.json|tsconfig\.json)$'; then
  checks+=("npm run -s typecheck" "npm test --silent" "npm run -s generate:check")
fi
[ ${#checks[@]} -gt 0 ] || exit 0

mkdir -p .build/agent
fingerprint="$( {
  printf '%s\n' "${checks[@]}"
  git diff HEAD --no-ext-diff
  git ls-files --others --exclude-standard -z | xargs -0 shasum 2>/dev/null
} | shasum | cut -d' ' -f1)"
stamp=".build/agent/stop-checks.ok"
[ -f "$stamp" ] && [ "$(cat "$stamp")" = "$fingerprint" ] && exit 0

for check in "${checks[@]}"; do
  log=".build/agent/last-check.log"
  if ! bash -c "$check" > "$log" 2>&1; then
    {
      echo "Проверка не прошла: $check"
      grep -v "\[MT\]" "$log" | tail -40
      echo "Исправьте и завершите снова. Если причина вне вашего контроля, объясните её пользователю."
    } >&2
    exit 2
  fi
done

echo "$fingerprint" > "$stamp"
exit 0
