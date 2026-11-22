#!/usr/bin/env bash
# Tests tools/apple/audit-scope.sh, which picks the catalog entries a pull request's accessibility audit covers
# (.github/workflows/ci.yml, `audit-scope`), against the repository as it stands: plain bash, perl, sed and awk, so
# tools/check.sh runs it on macOS and on Linux (step audit-scope). A second or so.
#
#   tools/apple/audit-scope-test.sh
#
# Cases: a changed path of each kind gives the entries it should (a WestronUI component's file, its generated contract
# and matrix, its catalog page, its contract, a self-contained Foundations page) or none (the registry, the generated
# registry of matrices, a shared file of WestronUI, a token file, the package manifest); every entry the registry holds
# is read from it, and every entry the catalog declares is in what the script reads, so that a change of the
# registry's shape fails here, not silently in CI; a registry the script reads nothing from fails it.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
script=tools/apple/audit-scope.sh
catalog=platforms/apple/Sources/WestronCatalog
failures=0

fail() {
  echo "audit-scope-test: FAIL: $*" >&2
  failures=$((failures + 1))
}
ok() { echo "audit-scope-test: ok: $*"; }

# Feeds <path> to the script and compares the line it prints with <expected>.
expect() {
  local path="$1" expected="$2" got
  if ! got="$(printf '%s\n' "$path" | "$script" 2> /dev/null)"; then
    fail "$path: the script failed"
  elif [ "$got" = "$expected" ]; then
    ok "$path → ${expected:-nothing}"
  else
    fail "$path → \"$got\", expected \"$expected\""
  fi
}

# A component's paths.
expect platforms/apple/Sources/WestronUI/ListRow/ListRow.swift list-row,list-row-in-list
expect platforms/apple/Sources/WestronUI/Disclosure/DisclosureVariantStyle.swift disclosure
expect platforms/apple/Sources/WestronUI/Generated/Disclosure+Contract.swift disclosure
expect "$catalog/Generated/Chip+Matrix.swift" chip
expect "$catalog/Components/DisclosurePages.swift" disclosure
expect spec/components/text-field/text-field.spec.yaml \
  text-field,text-field-behavior,text-field-focus-framed,text-field-focus-inline
# A Foundations page that shares nothing.
expect "$catalog/Foundations/MotionPage.swift" motion
# Shared paths and paths outside any component.
expect "$catalog/Catalog.swift" ""
expect "$catalog/Generated/ComponentMatrix+All.swift" ""
expect platforms/apple/Sources/WestronUI/TokenAdapters.swift ""
expect tokens/semantic/motion.tokens.json ""
expect Package.swift ""

# Every entry: the registry the script reads is the set of entries the catalog declares, each once.
registered="$("$script" --registry)" || fail "the script reads no registry"
declared="$(find "$catalog" -name '*.swift' -print0 | sort -z | xargs -0 perl -0777 -ne \
  'while (/static\s+let\s+(\w+)\s*=\s*CatalogEntry\(\s*id:/g) { print "$1\n" }' | sort)"
if [ "$(sort <<< "$registered")" = "$declared" ]; then
  ok "the registry reads as every entry the catalog declares ($(wc -l <<< "$declared" | tr -d ' '))"
else
  fail "the registry the script reads and the entries the catalog declares differ:"
  diff <(sort <<< "$registered") <(echo "$declared") >&2 || true
fi
duplicates="$(sort <<< "$registered" | uniq -d)"
[ -z "$duplicates" ] || fail "entries read twice from the registry: $duplicates"
# Every page's entries, fed at once, come back in the registry's order: the order the script prints.
pages="$(find "$catalog/Components" -name '*Pages.swift' | sort)"
all="$("$script" <<< "$pages" 2> /dev/null)"
want="$(while IFS= read -r name; do
  perl -0777 -ne 'while (/static\s+let\s+(\w+)\s*=\s*CatalogEntry\(\s*id:\s*"([^"]+)"/g) { print "$1 $2\n" }' \
    $pages | awk -v name="$name" '$1 == name { print $2 }'
done <<< "$registered" | paste -sd, -)"
if [ -n "$all" ] && [ "$all" = "$want" ]; then
  ok "every component page's entries, in the registry's order ($all)"
else
  fail "every component page gives \"$all\", expected \"$want\""
fi

# A registry in a shape the script cannot read fails it, rather than auditing nothing.
work="$(mktemp -d "${TMPDIR:-/tmp}/westron-audit-scope-test.XXXXXX")"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/tools/apple" "$work/$catalog/Components"
cp "$script" "$work/tools/apple/"
cp "$catalog/Components/ChipPages.swift" "$work/$catalog/Components/"
cat > "$work/$catalog/Catalog.swift" << 'EOF'
public enum Catalog {
    public static let entries: [CatalogEntry] = Registry.make()

    public static func entry(id: String) -> CatalogEntry? { nil }
}
EOF
if output="$(echo "$catalog/Components/ChipPages.swift" | "$work/tools/apple/audit-scope.sh" 2>&1)"; then
  fail "a registry read as empty did not fail the script: \"$output\""
elif grep -q "no entry read from the registry" <<< "$output"; then
  ok "a registry in an unknown shape fails the script"
else
  fail "a registry in an unknown shape failed the script with: $output"
fi

if [ "$failures" -gt 0 ]; then
  echo "audit-scope-test: $failures failed" >&2
  exit 1
fi
echo "audit-scope-test: all passed"
