#!/usr/bin/env bash
# Stop: does not let the agent finish its work until the checks of the affected parts pass.
#
# Affected means uncommitted changes and new files, and each check runs only when they touch what it reads (below).
# The result is remembered by a fingerprint of the changes (.build/agent/): after a success, stopping again without
# new edits reruns nothing. If a check failed and the agent stops again without changing anything, it is let go: it
# could not fix the failure and must explain the reason to the human. Exit code 2 returns the failed check and the tail
# of its output to the agent.
#
# --branch [<base>] (default base: main) is the same selection for work that is already committed, as the
# orchestrator's test gate runs it (.claude/test-command) in an implementer's worktree before it hands back. It works
# in the git checkout of the current directory, not in CLAUDE_PROJECT_DIR (the gate's points at the main checkout).
# Affected means everything since the merge base of HEAD with <base>, committed or not, and new files; a renamed
# file counts under both names. A missing base or merge base fails, and so does a missing Xcode. A failure fails
# every time (exit 1): there is no "unchanged since the last failure" release. A success is remembered by its own
# fingerprint (HEAD, the merge base, the uncommitted changes and new files), apart from the Stop hook's.
#
# WESTRON_STOP_CHECKS_DRY_RUN=1 prints the checks it would run, one per line, and exits 0 without running them or
# writing the fingerprint, in either mode.
set -uo pipefail

mode=stop
base=main
case "$#:${1:-}" in
  0:) ;;
  1:--branch) mode=branch ;;
  2:--branch) mode=branch base="$2" ;;
  *)
    echo "usage: stop-checks.sh [--branch [<base>]]" >&2
    exit 64
    ;;
esac

if [ "$mode" = branch ]; then
  fail() {
    echo "stop-checks --branch: $1" >&2
    exit 1
  }
  root="$(git rev-parse --show-toplevel 2> /dev/null)" || fail "$PWD is not in a git checkout"
  cd "$root" || fail "cannot enter $root"
  git rev-parse --verify --quiet "$base^{commit}" > /dev/null || fail "the base ref '$base' does not exist in $root"
  merge_base="$(git merge-base HEAD "$base")" || fail "HEAD and '$base' have no merge base in $root"
  tracked="$(git -c core.quotePath=false diff --name-only --no-renames "$merge_base" --)" ||
    fail "git could not list the changes since $merge_base in $root"
  untracked="$(git -c core.quotePath=false ls-files --others --exclude-standard)" ||
    fail "git could not list the new files in $root"
  changed="$(printf '%s\n%s\n' "$tracked" "$untracked" | grep -v '^$' | sort -u)"
else
  root="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
  cd "$root" || exit 0
  cat > /dev/null # the input JSON is not needed: a repeat without edits is recognized by the fingerprint

  changed="$(git -c core.quotePath=false status --porcelain --untracked-files=all | cut -c4- | sed 's/.* -> //')"
fi
[ -n "$changed" ] || exit 0

has() { grep -qE "$1" <<< "$changed"; }

# What each check reads. A change of the toolchain (the pinned Xcode and the script that finds it) touches every
# check; a change of the tools themselves (their package, sources, tests, schemas and scripts) every check of
# tools/check.sh, since each runs them.
toolchain='^(\.xcode-version|tools/apple/xcode-env\.sh)$'
tools_package='^tools/(Package\.swift|Package\.resolved|Sources/|Tests/|Schemas/|westron$|check\.sh$)'
package_manifest='^Package\.(swift|resolved)$'
westron_ui='^platforms/apple/Sources/WestronUI/'
westron_contract='^platforms/apple/Sources/WestronContract/'

# The Apple package and its catalog (tools/apple/check.sh). The package's unit tests also read the contracts
# (`contractFile` in platforms/apple/Tests), and the catalog's tests the patterns, whose Apple example the catalog runs
# (PatternExampleTests); the catalog app and its UI tests import WestronCatalog alone, and a
# change of WestronUI that breaks WestronCatalog fails `package` first. The catalog also compiles the snapshot tests
# (platforms/apple/Tests/WestronSnapshotTests, its hosted bundle CatalogSnapshotTests). The four checks are targets of
# tools/apple/check.sh, so a change of that script runs all four; simulator.sh serves only its targets the hook does not
# run (package-ios, a11y). Any other script in tools/apple/ (snapshot-matrix.sh, catalog-screenshot.sh,
# audit-scope.sh) runs none of them, only the syntax check below; the lock and its test (lock.sh, lock-test.sh) also
# run the step locks of tools/check.sh, and audit-scope.sh and its test the step audit-scope.
#
# The snapshot matrix itself is not rendered here. It is cheap on macOS (about 15 s) and repeatable, but a local render
# has nothing to be checked against: the references are the CI runner's (platforms/apple/Snapshots/), and `check`
# says the environment differs. The CI job `snapshots` checks it; an agent compares renders before and after a change
# (/visual-check). What the hook checks of it: the page builder compiles, and a reference environment file is JSON.
apple_script='^tools/apple/check\.sh$'
swift_sources='^(Package\.swift|platforms/apple/.*\.swift|tools/(Package\.swift|Sources/.*\.swift|Tests/.*\.swift))$'
format_inputs="$swift_sources|^\.swift-format$|$apple_script|$toolchain"
package_inputs="$package_manifest|^platforms/apple/(Sources|Tests)/|^spec/components/[^/]+/[^/]+\.spec\.yaml$|^spec/patterns/|$apple_script|$toolchain"
platforms_inputs="$package_manifest|^platforms/apple/Sources/|$apple_script|$toolchain"
snapshot_tests='^platforms/apple/Tests/WestronSnapshotTests/'
catalog_inputs="$package_manifest|^platforms/apple/Catalog/|^platforms/apple/Sources/WestronCatalog/|$snapshot_tests|$apple_script|$toolchain"

# The steps of tools/check.sh, each with what its command reads by default (tools/Sources, but for locks). The data:
# the token files, the resolver and the palette; the contracts, their schema and the icon registry; not the Markdown
# beside them, but for the two documents the agent context reads, spec/conventions.md and the design language, the
# patterns (spec/patterns/, decisions/0018), which it checks and copies, and its output, the plugin's
# plugins/westron/skills/westron/context/ and llms.txt (generate). The tools' own tests read the repository too
# (`repositoryRoot` in tools/Tests: the tokens, the contracts and their schema, the icon registry, the two documents,
# the patterns, the skill's hand-written SKILL.md, the sources of WestronUI and WestronContract and the generated
# Swift, .xcode-version), so they run for those as well. The step patterns reads the patterns and, to hold them, the
# contracts, the tokens and the icon registry. The lint api-parity reads WestronUI and WestronContract, the
# module of the contracts' enums (decisions/0017). The step locks reads only the lock and its test, plain bash; the
# step audit-scope reads the script, its test and the sources it maps (the catalog, the components of WestronUI and
# WestronContract, the contracts, the patterns), plain bash too. A
# change of the tools or of the toolchain selects them all the same, as it selects every step, and the hook then runs
# plain tools/check.sh.
tokens='^tokens/.*\.json$'
spec='^spec/(components/[^/]+/[^/]+\.spec\.yaml$|schema/|icons/)'
generated='^platforms/apple/Sources/(WestronTokens/Generated/|WestronContract/Generated/|WestronUI/Generated/|WestronUI/Tokens\.xcassets/|WestronCatalog/Generated/)'
# The agent context (decisions/0016): the generator also reads the platform conventions, the design language and the
# patterns, and writes the bundle into the skill of westron's Claude Code plugin and llms.txt at the root; the tools'
# tests read the skill's SKILL.md.
agent_context_inputs='^(spec/conventions\.md|design-language/|spec/patterns/)'
agent_context_outputs='^(plugins/westron/skills/westron/context/|llms\.txt$)'
skill='^plugins/westron/skills/westron/SKILL\.md$'
tools_steps=(
  "tools|$tokens|$spec|$westron_ui|$westron_contract|^platforms/apple/Sources/WestronTokens/|$agent_context_inputs|$skill"
  "raw-values|$westron_ui"
  "generate|$tokens|$spec|$generated|$agent_context_inputs|$agent_context_outputs"
  "tokens|$tokens"
  "contrast|$tokens"
  "icons|^spec/icons/"
  "spec|$spec|$tokens"
  "patterns|^spec/patterns/|$spec|$tokens"
  "api-parity|$westron_ui|$westron_contract|$spec"
  "locks|^tools/apple/lock(-test)?\.sh$"
  "audit-scope|^tools/apple/audit-scope(-test)?\.sh$|^platforms/apple/Sources/(WestronCatalog|WestronUI|WestronContract)/|^spec/(components|patterns)/"
)

checks=()
# Every changed shell script of the tools and the hooks is parsed (`bash -n`, a fraction of a second): most of them
# no other check runs.
while IFS= read -r script; do
  [ -f "$script" ] && checks+=("bash -n $(printf '%q' "$script")")
done < <(grep -E '^(tools/.*\.sh|tools/westron|\.claude/hooks/.*\.sh)$' <<< "$changed")
# The snapshot matrix's page builder and comparison, compiled by snapshot-matrix.sh only when it runs: type-checked
# here. A reference set's environment file, which `check` and `record` read with jq: parsed.
if has '^tools/apple/snapshot-pages\.swift$|'"$toolchain"; then
  checks+=("source tools/apple/xcode-env.sh && xcrun --sdk macosx swiftc -typecheck tools/apple/snapshot-pages.swift")
fi
while IFS= read -r file; do
  [ -f "$file" ] && checks+=("jq -e . $(printf '%q' "$file") > /dev/null")
done < <(grep -E '^platforms/apple/Snapshots/[^/]+/environment\.json$' <<< "$changed")
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

if [ "$mode" = branch ]; then
  (source tools/apple/xcode-env.sh) 2> /dev/null ||
    fail "Xcode $(cat .xcode-version) not found, so the checks cannot run: ${checks[*]}"

  mkdir -p .build/agent
  fingerprint="$( {
    echo "branch"
    printf '%s\n' "${checks[@]}"
    git rev-parse HEAD
    echo "$merge_base"
    git diff HEAD --no-ext-diff --binary
    git ls-files --others --exclude-standard -z | xargs -0 shasum 2> /dev/null
  } | shasum | cut -d' ' -f1)"
  passed=".build/agent/branch-checks.passed"
  if [ -f "$passed" ] && [ "$(cat "$passed")" = "$fingerprint" ]; then
    echo "stop-checks --branch: passed before with these changes: ${checks[*]}"
    exit 0
  fi

  for check in "${checks[@]}"; do
    log=".build/agent/branch-check.log"
    echo "stop-checks --branch: $check"
    if ! bash -c "$check" > "$log" 2>&1; then
      {
        echo "Check failed: $check"
        grep -v "\[MT\]" "$log" | tail -40
        echo "Changes since $base ($(git rev-parse --short "$merge_base")) in $root. Fix it and run again."
      } >&2
      exit 1
    fi
  done

  echo "$fingerprint" > "$passed"
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
