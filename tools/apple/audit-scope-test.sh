#!/usr/bin/env bash
# Tests tools/apple/audit-scope.sh, which picks the catalog entries a pull request's accessibility audit covers
# (.github/workflows/ci.yml, `audit-scope`), against the repository as it stands and against copies of its sources
# with one use added: plain bash, perl, sed and awk, so tools/check.sh runs it on macOS and on Linux (step
# audit-scope). Ten seconds or so.
#
#   tools/apple/audit-scope-test.sh
#
# Cases:
#   - a changed path of each kind gives exactly the entries it should (a WestronUI component's file, its generated
#     contract and matrix, its catalog page, its contract, a self-contained Foundations page, a pattern's document
#     and its catalog source) or none (a pattern with no example in the catalog yet, the registry, the generated
#     registry of matrices, a shared file of WestronUI, a token file, the package manifest);
#   - use: a component's change also gives exactly the entries that draw it (Disclosure's: list-row; Checkbox's:
#     list-row, list-row-in-list, disclosure; IconTile's: the pattern entry choice-list-sheet), not the entries that
#     reach it only through a base component (Rule's: color-in-use and choice-list-sheet, not list-row, whose
#     insertion mark is ListRow's), and not the entries that call a system style or another component's of the same name (Button's change does not give disclosure, whose page calls
#     `.buttonStyle(.plain)`; Checkbox's does not give chip, `.toggleStyle(.chip)`);
#   - the declared base components and every component's count beyond its own entries, pinned (`--uses`): a change
#     of either fails here and asks for a look at the cut and the limit;
#   - the registry: every entry it holds is read from it, and every entry the catalog declares is in what the script
#     reads, so that a change of its shape fails here, not silently in CI; a registry read as empty fails the script;
#   - in copies of the sources, each with one use added, with no change to the script: a use through a type, a
#     top-level `let`, an extension's property (`\.forcedChipStates`), a function (`.onChipHover { … }`), an
#     initializer added to a system type (`Toggle(isOn:accessibilityLabel:)`) is followed; a use inside a base
#     component (Icon) is not followed on through it; a new use that takes a component past the limit fails the
#     script with the decision to make (`.surface(.raised)` or `.surface(flag ? .raised : .sunken)` on the chip entry,
#     a primary Button on it), while one more entry drawing a base component (a ListRow on it) does not; a base
#     component declared within the limit fails it as stale; an entry where the scan does not look fails it.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
script=tools/apple/audit-scope.sh
ui=platforms/apple/Sources/WestronUI
contract=platforms/apple/Sources/WestronContract
catalog=platforms/apple/Sources/WestronCatalog
failures=0

fail() {
  echo "audit-scope-test: FAIL: $*" >&2
  failures=$((failures + 1))
}
ok() { echo "audit-scope-test: ok: $*"; }

# Feeds <path> to <script> (default: the repository's) and compares the line it prints with <expected>; <label>, if
# given, names the case instead of the path.
expect() {
  local path="$1" expected="$2" run="${3:-$script}" label="${4:-$1}" got
  if ! got="$(printf '%s\n' "$path" | "$run" 2> /dev/null)"; then
    fail "$label: the script failed"
  elif [ "$got" = "$expected" ]; then
    ok "$label → ${expected:-nothing}"
  else
    fail "$label → \"$got\", expected \"$expected\""
  fi
}

# A component's paths.
expect "$ui/Generated/Disclosure+Contract.swift" list-row,disclosure
# Its enums in WestronContract (decisions/0017): the same entries as the component's other generated file.
expect "$contract/Generated/Disclosure+Contract.swift" list-row,disclosure
expect "$contract/Generated/Rule+Contract.swift" rule,choice-list-sheet,color-in-use
expect "$catalog/Generated/Chip+Matrix.swift" chip
expect "$catalog/Components/DisclosurePages.swift" disclosure
expect spec/components/text-field/text-field.spec.yaml \
  text-field,text-field-glyphs,text-field-behavior,text-field-focus-framed,text-field-focus-inline
# Use, exactly.
expect "$ui/Disclosure/DisclosureVariantStyle.swift" list-row,disclosure
# Not through a base component: list-row draws Rule only inside ListRow (its insertion mark).
expect "$ui/Rule/Rule.swift" rule,choice-list-sheet,color-in-use
# Not a use: the system's `.buttonStyle(.plain)` (Disclosure's page) and Chip's `.toggleStyle(.chip)`.
expect "$ui/Button/ButtonVariantStyle.swift" "button,button-destructive,button-states,button-states-destructive,\
button-states-destructive-disabled,button-behavior,button-floating,button-floating-sizes,button-floating-states,\
button-floating-before-26,text-field-behavior,text-field-focus-framed,text-field-focus-inline,color-in-use,controls"
expect "$ui/Checkbox/CheckboxVariantStyle.swift" checkbox,checkbox-in-list,list-row,list-row-in-list,disclosure
expect "$ui/Chip/ChipStyles.swift" chip
expect "$catalog/Components/ButtonPages.swift" "button,button-destructive,button-states,button-states-destructive,\
button-states-destructive-disabled,button-behavior,button-floating,button-floating-sizes,button-floating-states,\
button-floating-before-26,checkbox,chip,color-categories,color-in-use,controls"
# A base component: its own entries only, and it says so.
expect "$ui/Icon/Icon.swift" icon
expect "$ui/ListRow/ListRow.swift" list-row,list-row-in-list
for base in Icon ListRow; do
  if printf '%s\n' "$ui/$base/$base.swift" | "$script" 2>&1 > /dev/null |
    grep -q "$base is a base component.*nightly run"; then
    ok "$base's change says it is a base component"
  else
    fail "$base's change does not say it is a base component"
  fi
done
# A Foundations page that shares nothing.
expect "$catalog/Foundations/MotionPage.swift" motion
# A pattern (decisions/0018): its document and each file of its catalog directory give its entry; a pattern with no
# directory in the catalog gives nothing; a component its entry draws gives it too.
expect spec/patterns/choice-list-sheet.md choice-list-sheet
expect "$catalog/Patterns/ChoiceListSheet/ChoiceSheet.swift" choice-list-sheet
expect "$catalog/Patterns/ChoiceListSheet/ChoiceListSheetPage.swift" choice-list-sheet
expect spec/patterns/empty-state.md empty-state
expect "$catalog/Patterns/EmptyState/EmptyState.swift" empty-state
expect "$catalog/Patterns/EmptyState/EmptyStatePage.swift" empty-state
expect spec/patterns/no-such-pattern.md ""
expect "$ui/IconTile/IconTile.swift" icon-tile,choice-list-sheet,empty-state
# Shared paths and paths outside any component.
expect "$catalog/Catalog.swift" ""
expect "$catalog/Generated/ComponentMatrix+All.swift" ""
expect "$ui/TokenAdapters.swift" ""
expect tokens/semantic/motion.tokens.json ""
expect Package.swift ""

# The declared base components and every count beyond a component's own entries. Three stand at the limit, 5, on
# purpose (the script's header, "Use"): when one of them changes, look at the cut before you update this.
margins="$("$script" --uses 2> /dev/null | grep -v '^ ' |
  sed -E 's/^([A-Za-z]+ [a-z]+: [0-9]+( \(base component)?).*/\1/')"
want_margins="Button impl: 5
Button page: 5
Checkbox impl: 3
Checkbox page: 0
Chip impl: 0
Chip page: 0
Disclosure impl: 1
Disclosure page: 0
Icon impl: 0 (base component
Icon page: 0 (base component
IconTile impl: 1
IconTile page: 0
ListRow impl: 0 (base component
ListRow page: 0 (base component
Rule impl: 2
Rule page: 0
Surface impl: 5
Surface page: 0
Text impl: 0
Text page: 0
TextField impl: 0
TextField page: 0"
if [ "$margins" = "$want_margins" ]; then
  ok "the base components (Icon, ListRow) and every count beyond a component's own entries, as pinned"
else
  fail "the counts beyond a component's own entries changed; look at the cut and the limit, then update this:"
  diff <(echo "$want_margins") <(echo "$margins") >&2 || true
fi

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
# Every component page at once: their entries and those that use their code, in the registry's order.
expect "$(find "$catalog/Components" -name '*Pages.swift' | sort)" "button,button-destructive,button-states,\
button-states-destructive,button-states-destructive-disabled,button-behavior,button-floating,button-floating-sizes,\
button-floating-states,button-floating-before-26,text,icon,icon-tile,surface,rule,checkbox,checkbox-in-list,chip,\
list-row,list-row-in-list,disclosure,text-field,text-field-glyphs,text-field-behavior,text-field-focus-framed,\
text-field-focus-inline,color-categories,color-in-use,controls" "" "every component page at once"

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

# Copies of the sources, each with one use added; the script follows it with no change of its own.
copy="$work/copy"
copy_script="$copy/tools/apple/audit-scope.sh"
fresh_copy() {
  rm -rf "$copy"
  mkdir -p "$copy/tools/apple" "$copy/platforms/apple/Sources"
  cp "$script" "$copy/tools/apple/"
  cp -R "$ui" "$contract" "$catalog" "$copy/platforms/apple/Sources/"
}
# Adds the code <line> to the body of the entry <name> in the page <file> of the copy.
add_to_entry() {
  local file="$copy/$1" name="$2" line="$3"
  LINE="$line" perl -0pi -e 's/(static let \Q'"$name"'\E = CatalogEntry\([^{]*\{\n)/$1        $ENV{LINE}\n/' "$file"
  grep -qF "        $line" "$file" || fail "the entry $name in $1 could not be given \"$line\": its shape changed"
}
# Expects the copy's script to fail on <path> with output that matches <pattern>.
expect_failure() {
  local path="$1" pattern="$2" what="$3" output
  if output="$(echo "$path" | "$copy_script" 2>&1)"; then
    fail "$what did not fail the script: \"$output\""
  elif grep -qE "$pattern" <<< "$output"; then
    ok "$what fails the script: $(grep -E "$pattern" <<< "$output" | head -1 | cut -c1-140)…"
  else
    fail "$what failed the script with: $output"
  fi
}

rule_page="$catalog/Components/RulePages.swift"
chip_page="$catalog/Components/ChipPages.swift"
fresh_copy
add_to_entry "$chip_page" chip 'Rule()'
expect "$ui/Rule/Rule.swift" rule,chip,choice-list-sheet,color-in-use "$copy_script" \
  "a type (the chip entry draws a Rule): Rule.swift"
fresh_copy
echo 'let auditScopeProbe = ChipVariant.chip' >> "$copy/$catalog/Foundations/AdaptiveGrid.swift"
add_to_entry "$rule_page" rule 'EmptyView().id(auditScopeProbe)'
expect "$ui/Chip/ChipStyles.swift" rule,chip "$copy_script" \
  "a top-level let (the rule entry, auditScopeProbe = ChipVariant.chip): ChipStyles.swift"
fresh_copy
add_to_entry "$rule_page" rule 'EmptyView().environment(\.forcedChipStates, [])'
expect "$ui/Chip/ChipStyles.swift" rule,chip "$copy_script" \
  "an extension's property (the rule entry, \\.forcedChipStates): ChipStyles.swift"
fresh_copy
add_to_entry "$rule_page" rule 'EmptyView().onChipHover { _ in }'
expect "$ui/Chip/ChipStyles.swift" rule,chip "$copy_script" \
  "a function (the rule entry, .onChipHover { … }): ChipStyles.swift"
fresh_copy
add_to_entry "$rule_page" rule 'Toggle(isOn: .constant(true), accessibilityLabel: "Probe")'
expect "$ui/Checkbox/CheckboxVariantStyle.swift" rule,checkbox,checkbox-in-list,list-row,list-row-in-list,disclosure \
  "$copy_script" "an initializer on Toggle (the rule entry, Toggle(isOn:accessibilityLabel:)):"\
" CheckboxVariantStyle.swift"
# Icon, a base component, drawing a Chip: Chip's change selects Icon's users neither through it nor past the limit.
fresh_copy
printf '\nextension Icon {\n    var auditScopeProbe: ChipVariant { .chip }\n}\n' >> "$copy/$ui/Icon/Icon.swift"
expect "$ui/Chip/ChipStyles.swift" chip "$copy_script" \
  "a use inside Icon, a base component (Icon draws ChipVariant): ChipStyles.swift"
# The tripwire: a new use that takes a component past the limit fails the script, which says what to decide.
decision="would select 6 entries beyond its own, more than the limit of 5.*Decide.*declare (Surface|Button) a base"
fresh_copy
add_to_entry "$chip_page" chip 'EmptyView().surface(.raised)'
expect_failure "$ui/Surface/Surface.swift" "a change to Surface $decision" \
  "a sixth entry drawing Surface (the chip entry, .surface(.raised))"
expect_failure "$catalog/Foundations/MotionPage.swift" "a change to Surface $decision" \
  "that use, on a pull request that changes no component"
fresh_copy
add_to_entry "$chip_page" chip 'EmptyView().surface(flag ? .raised : .sunken)'
expect_failure "$ui/Surface/Surface.swift" "a change to Surface $decision" \
  "a sixth entry drawing Surface with no case written out (.surface(flag ? .raised : .sunken))"
fresh_copy
add_to_entry "$chip_page" chip 'Button("Probe") {}.buttonStyle(.primary)'
expect_failure "$ui/Button/ButtonVariantStyle.swift" "a change to Button $decision" \
  "a sixth entry drawing Button (the chip entry, .buttonStyle(.primary))"
# One more entry drawing a base component is past no limit: ListRow's change still gives its own entries only.
fresh_copy
add_to_entry "$chip_page" chip 'ListRow { Text("Probe") }'
expect "$ui/ListRow/ListRow.swift" list-row,list-row-in-list "$copy_script" \
  "an eighth entry drawing ListRow, a base component (the chip entry, a ListRow): ListRow.swift"
# A base component declared within the limit fails the script: its declaration is stale.
fresh_copy
perl -0pi -e 's/^(base_components=")\n/$1\nChip: a probe of the test\n/m' "$copy_script"
expect_failure "$ui/Chip/ChipStyles.swift" "Chip is declared a base component.*stale" \
  "Chip declared base, within the limit"
# An entry where the scan does not look for one fails the script, rather than being left out of every scope.
fresh_copy
cat >> "$copy/$chip_page" << 'EOF'

struct OddEntries {
    static let odd = CatalogEntry(id: "odd", title: "Odd", section: .components) { ChipPage() }
}
EOF
expect_failure "$ui/Rule/Rule.swift" "is not a static let in an extension of CatalogEntry" \
  "an entry outside an extension of CatalogEntry"

if [ "$failures" -gt 0 ]; then
  echo "audit-scope-test: $failures failed" >&2
  exit 1
fi
echo "audit-scope-test: all passed"
