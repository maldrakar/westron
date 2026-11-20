#!/usr/bin/env bash
# Stop: does not let the agent finish its work until the checks of the affected parts pass.
#
# Affected means uncommitted changes and new files, and each check runs only when they touch what it reads (below).
# The result is remembered by a fingerprint of the changes (.build/agent/): after a success, stopping again without
# new edits reruns nothing. If a check failed and the agent stops again without changing anything, it is let go: it
# could not fix the failure and must explain the reason to the human. Exit code 2 returns the failed check and the tail
# of its output to the agent.
#
# WESTRON_STOP_CHECKS_DRY_RUN=1 prints the checks it would run, one per line, and exits 0 without running them or
# writing the fingerprint.
set -uo pipefail

root="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$root" || exit 0
cat > /dev/null # the input JSON is not needed: a repeat without edits is recognized by the fingerprint

changed="$(git -c core.quotePath=false status --porcelain --untracked-files=all | cut -c4- | sed 's/.* -> //')"
[ -n "$changed" ] || exit 0

has() { grep -qE "$1" <<< "$changed"; }

# What each check reads. A change of the toolchain (the pinned Xcode and the script that finds it) touches every
# check; a change of the tools themselves (their package, sources, tests, schemas and scripts) every check of
# tools/check.sh, since each runs them.
toolchain='^(\.xcode-version|tools/apple/xcode-env\.sh)$'
tools_package='^tools/(Package\.swift|Package\.resolved|Sources/|Tests/|Schemas/|westron$|check\.sh$)'
package_manifest='^Package\.(swift|resolved)$'
westron_ui='^platforms/apple/Sources/WestronUI/'

# The Apple package and its catalog (tools/apple/check.sh). The package's unit tests also read the contracts
# (`contractFile` in platforms/apple/Tests); the catalog app and its UI tests import WestronCatalog alone, and a
# change of WestronUI that breaks WestronCatalog fails `package` first. The four checks are targets of
# tools/apple/check.sh, so a change of that script runs all four; simulator.sh serves only its targets the hook does not
# run (package-ios, a11y). Any other script in tools/apple/ (snapshot-matrix.sh, catalog-screenshot.sh,
# audit-scope.sh) runs none of them, only the syntax check below.
apple_script='^tools/apple/check\.sh$'
swift_sources='^(Package\.swift|platforms/apple/.*\.swift|tools/(Package\.swift|Sources/.*\.swift|Tests/.*\.swift))$'
format_inputs="$swift_sources|^\.swift-format$|$apple_script|$toolchain"
package_inputs="$package_manifest|^platforms/apple/(Sources|Tests)/|^spec/components/[^/]+/[^/]+\.spec\.yaml$|$apple_script|$toolchain"
platforms_inputs="$package_manifest|^platforms/apple/Sources/|$apple_script|$toolchain"
catalog_inputs="$package_manifest|^platforms/apple/Catalog/|^platforms/apple/Sources/WestronCatalog/|$apple_script|$toolchain"

# The steps of tools/check.sh, each with what its command reads by default (tools/Sources). The data: the token
# files, the resolver and the palette; the contracts, their schema and the icon registry; not the Markdown beside
# them. The tools' own tests read the repository too (`repositoryRoot` in tools/Tests: the tokens, the contracts and
# their schema, the icon registry, WestronUI's sources and the generated Swift, .xcode-version), so they run for those
# as well.
tokens='^tokens/.*\.json$'
spec='^spec/(components/[^/]+/[^/]+\.spec\.yaml$|schema/|icons/)'
generated='^platforms/apple/Sources/(WestronTokens/Generated/|WestronUI/Generated/|WestronUI/Tokens\.xcassets/|WestronCatalog/Generated/)'
tools_steps=(
  "tools|$tokens|$spec|$westron_ui|^platforms/apple/Sources/WestronTokens/"
  "raw-values|$westron_ui"
  "generate|$tokens|$spec|$generated"
  "tokens|$tokens"
  "contrast|$tokens"
  "icons|^spec/icons/"
  "spec|$spec|$tokens"
  "api-parity|$westron_ui|$spec"
)

checks=()
# Every changed shell script of the tools and the hooks is parsed (`bash -n`, a fraction of a second): most of them
# no other check runs.
while IFS= read -r script; do
  [ -f "$script" ] && checks+=("bash -n $(printf '%q' "$script")")
done < <(grep -E '^(tools/.*\.sh|tools/westron|\.claude/hooks/.*\.sh)$' <<< "$changed")
has "$format_inputs" && checks+=("tools/apple/check.sh format")
has "$package_inputs" && checks+=("tools/apple/check.sh package")
has "$platforms_inputs" && checks+=("tools/apple/check.sh platforms")
has "$catalog_inputs" && checks+=("tools/apple/check.sh catalog")
steps=()
for entry in "${tools_steps[@]}"; do
  if has "${entry#*|}|$tools_package|$toolchain"; then steps+=("${entry%%|*}"); fi
done
if [ ${#steps[@]} -eq ${#tools_steps[@]} ]; then
  checks+=("tools/check.sh")
elif [ ${#steps[@]} -gt 0 ]; then
  checks+=("tools/check.sh ${steps[*]}")
fi
[ ${#checks[@]} -gt 0 ] || exit 0

if [ -n "${WESTRON_STOP_CHECKS_DRY_RUN:-}" ]; then
  printf '%s\n' "${checks[@]}"
  exit 0
fi

if ! (source tools/apple/xcode-env.sh) 2> /dev/null; then
  echo "stop-checks: Xcode $(cat .xcode-version) not found, so the Swift checks are skipped" >&2
  exit 0
fi

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
