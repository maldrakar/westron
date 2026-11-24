#!/usr/bin/env bash
# Tests tools/apple/audit-scope.sh, which picks the catalog entries a pull request's accessibility audit covers
# (.github/workflows/ci.yml, `audit-scope`), against the repository as it stands: plain bash, perl, sed and awk, so
# tools/check.sh runs it on macOS and on Linux (step audit-scope). A few seconds.
#
#   tools/apple/audit-scope-test.sh
#
# Cases: a changed path of each kind gives the entries it should (a WestronUI component's file, its generated contract
# and matrix, its catalog page, its contract, a self-contained Foundations page) or none (the registry, the generated
# registry of matrices, a shared file of WestronUI, a token file, the package manifest); a component's change also
# selects the entries that draw it (ListRow's: disclosure and the floating Button entries; Rule's: list-row), and a
# base component past the cut (Icon) only its own, saying so; every entry the registry holds is read from it, and
# every entry the catalog declares is in what the script reads, so that a change of the registry's shape fails here,
# not silently in CI; a registry the script reads nothing from fails it; in a copy of the sources, a new use (the chip
# entry draws a Rule) is followed with no change to the script, and an entry where the scan does not look fails it.
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

# Feeds <path> to the script and checks that the line it prints holds each of <ids> (comma-separated).
expect_has() {
  local path="$1" want="$2" got id missing=""
  if ! got="$(printf '%s\n' "$path" | "$script" 2> /dev/null)"; then
    fail "$path: the script failed"
    return
  fi
  for id in ${want//,/ }; do
    [[ ",$got," == *",$id,"* ]] || missing+="${missing:+,}$id"
  done
  if [ -z "$missing" ]; then
    ok "$path → $got (holds $want)"
  else
    fail "$path → \"$got\", without $missing"
  fi
}

# A component's paths.
expect platforms/apple/Sources/WestronUI/Generated/Disclosure+Contract.swift list-row,disclosure
expect "$catalog/Generated/Chip+Matrix.swift" chip
expect "$catalog/Components/DisclosurePages.swift" disclosure
expect spec/components/text-field/text-field.spec.yaml \
  text-field,text-field-glyphs,text-field-behavior,text-field-focus-framed,text-field-focus-inline
# Use: a component's change also selects the entries that draw it, through other components too.
expect_has platforms/apple/Sources/WestronUI/ListRow/ListRow.swift list-row,list-row-in-list,disclosure,button-floating
expect_has platforms/apple/Sources/WestronUI/Disclosure/DisclosureVariantStyle.swift disclosure,list-row
expect_has platforms/apple/Sources/WestronUI/Rule/Rule.swift rule,list-row,list-row-in-list
expect_has platforms/apple/Sources/WestronUI/Checkbox/CheckboxVariantStyle.swift checkbox,list-row,disclosure
expect_has "$catalog/Components/ButtonPages.swift" button,checkbox,chip
# The cut: Icon is drawn on more entries than one leg holds, so its change selects its own only, and says so.
expect platforms/apple/Sources/WestronUI/Icon/Icon.swift icon
if printf '%s\n' platforms/apple/Sources/WestronUI/Icon/Icon.swift | "$script" 2>&1 > /dev/null |
  grep -q "more than 5 (the cut).*nightly run"; then
  ok "Icon's change names the cut"
else
  fail "Icon's change does not name the cut"
fi
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
# Pages' code other pages use adds entries of theirs (FlowLayout, used by the color pages), so the output holds every
# page's entries and maybe more, in the registry's order.
pages="$(find "$catalog/Components" -name '*Pages.swift' | sort)"
all="$("$script" <<< "$pages" 2> /dev/null)"
entry_ids() {
  perl -0777 -ne 'while (/static\s+let\s+(\w+)\s*=\s*CatalogEntry\(\s*id:\s*"([^"]+)"/g) { print "$1 $2\n" }' "$@"
}
# shellcheck disable=SC2046,SC2086 # the paths have no spaces
catalog_ids="$(entry_ids $(find "$catalog" -name '*.swift'))" page_ids="$(entry_ids $pages | cut -d' ' -f2)"
want="$(while IFS= read -r name; do
  id="$(awk -v name="$name" '$1 == name { print $2 }' <<< "$catalog_ids")"
  if grep -qxF "$id" <<< "$page_ids" || [[ ",$all," == *",$id,"* ]]; then echo "$id"; fi
done <<< "$registered" | paste -sd, -)"
if [ -n "$all" ] && [ "$all" = "$want" ]; then
  ok "every component page's entries and those that use them, in the registry's order ($all)"
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

# A new use is followed with no change to the script: in a copy of the sources, the chip entry draws a Rule too, and
# Rule's change then selects it.
copy="$work/uses"
mkdir -p "$copy/tools/apple" "$copy/platforms/apple/Sources"
cp "$script" "$copy/tools/apple/"
cp -R platforms/apple/Sources/WestronUI "$catalog" "$copy/platforms/apple/Sources/"
rule=platforms/apple/Sources/WestronUI/Rule/Rule.swift
chip_page="$copy/$catalog/Components/ChipPages.swift"
if [[ ",$(echo "$rule" | "$script" 2> /dev/null)," == *,chip,* ]]; then
  fail "Rule's change selects chip already: the next case proves nothing; give it another component"
fi
perl -0pi -e 's/(static let chip = CatalogEntry\([^{]*\{\n\s*ChipPage\(\))/$1\n        Rule()/' "$chip_page"
if ! grep -q '^        Rule()$' "$chip_page"; then
  fail "the chip entry of the copy could not be given a Rule: its shape changed; update this case"
elif [[ ",$(echo "$rule" | "$copy/tools/apple/audit-scope.sh" 2> /dev/null)," == *,chip,* ]]; then
  ok "a new use (the chip entry draws a Rule) is followed: Rule's change selects chip"
else
  fail "a new use (the chip entry draws a Rule) is not followed: Rule's change does not select chip"
fi
# An entry where the scan does not look for one fails the script, rather than being left out of every scope.
cat >> "$chip_page" << 'EOF'

struct OddEntries {
    static let odd = CatalogEntry(id: "odd", title: "Odd", section: .components) { ChipPage() }
}
EOF
if output="$(echo "$rule" | "$copy/tools/apple/audit-scope.sh" 2>&1)"; then
  fail "an entry outside an extension of CatalogEntry did not fail the script: \"$output\""
elif grep -q "is not a static let in an extension of CatalogEntry" <<< "$output"; then
  ok "an entry outside an extension of CatalogEntry fails the script"
else
  fail "an entry outside an extension of CatalogEntry failed the script with: $output"
fi

if [ "$failures" -gt 0 ]; then
  echo "audit-scope-test: $failures failed" >&2
  exit 1
fi
echo "audit-scope-test: all passed"
