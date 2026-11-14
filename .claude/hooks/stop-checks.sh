#!/usr/bin/env bash
# Stop: does not let the agent finish its work until the checks of the affected parts pass.
#
# Affected means uncommitted changes and new files. The result is remembered by a fingerprint of the changes
# (.build/agent/): after a success, stopping again without new edits reruns nothing. If a check failed
# and the agent stops again without changing anything, it is let go: it could not fix the failure and must
# explain the reason to the human. Exit code 2 returns the failed check and the tail of its output to the agent.
set -uo pipefail

root="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$root" || exit 0
cat > /dev/null # the input JSON is not needed: a repeat without edits is recognized by the fingerprint

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
    echo "stop-checks: Xcode $(cat .xcode-version) not found, so the Swift checks are skipped" >&2
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
      echo "Check failed: $check"
      grep -v "\[MT\]" "$log" | tail -40
      echo "Fix it and finish again. If it cannot be fixed, explain the reason to the human."
    } >&2
    exit 2
  fi
done

rm -f "$failed"
echo "$fingerprint" > "$passed"
exit 0
