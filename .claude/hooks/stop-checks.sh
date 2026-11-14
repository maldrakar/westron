#!/usr/bin/env bash
# Stop: не даёт агенту закончить работу, пока не пройдут проверки затронутых частей.
#
# Затронутое — незакоммиченные изменения и новые файлы. Результат запоминается по отпечатку изменений
# (.build/agent/): после успеха повторная остановка без новых правок ничего не перезапускает. Если проверка
# упала, а агент остановился снова, ничего не поменяв, его отпускают — значит, исправить он не смог и должен
# объяснить причину человеку. Код 2 возвращает агенту упавшую проверку и хвост её вывода.
set -uo pipefail

root="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$root" || exit 0
cat > /dev/null # входной JSON не нужен: повтор без правок распознаётся по отпечатку

changed="$(git -c core.quotePath=false status --porcelain --untracked-files=all | cut -c4- | sed 's/.* -> //')"
[ -n "$changed" ] || exit 0

has() { grep -qE "$1" <<< "$changed"; }

checks=()
if has '^(Package\.swift|\.swift-format|\.xcode-version|platforms/apple/|tools/apple/)'; then
  if (source tools/apple/xcode-env.sh) 2> /dev/null; then
    checks+=("tools/apple/check.sh format" "tools/apple/check.sh package")
    if has '^(Package\.swift|platforms/apple/Sources/)'; then
      checks+=("tools/apple/check.sh platforms")
    fi
    if has '^(Package\.swift|platforms/apple/Catalog/|platforms/apple/Sources/WestronCatalog/)'; then
      checks+=("tools/apple/check.sh catalog")
    fi
  else
    echo "stop-checks: Xcode $(cat .xcode-version) не найден — проверки Swift пропущены" >&2
  fi
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
  git ls-files --others --exclude-standard -z | xargs -0 shasum 2> /dev/null
} | shasum | cut -d' ' -f1)"
passed=".build/agent/stop-checks.passed"
failed=".build/agent/stop-checks.failed"
[ -f "$passed" ] && [ "$(cat "$passed")" = "$fingerprint" ] && exit 0
[ -f "$failed" ] && [ "$(cat "$failed")" = "$fingerprint" ] && exit 0

for check in "${checks[@]}"; do
  log=".build/agent/last-check.log"
  if ! bash -c "$check" > "$log" 2>&1; then
    echo "$fingerprint" > "$failed"
    {
      echo "Проверка не прошла: $check"
      grep -v "\[MT\]" "$log" | tail -40
      echo "Исправьте и завершите снова. Если исправить нельзя, объясните причину человеку."
    } >&2
    exit 2
  fi
done

rm -f "$failed"
echo "$fingerprint" > "$passed"
exit 0
