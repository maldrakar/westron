#!/usr/bin/env bash
# Which catalog entries a pull request's accessibility audit covers (.github/workflows/ci.yml, `audit-scope`).
#
#   git diff --name-only <base> <head> | tools/apple/audit-scope.sh
#
# Reads changed paths, one per line, and prints one line: the ids of the catalog entries to audit, comma-separated,
# in the order of the registry (`Catalog.entries`), or an empty line when there is nothing to audit. Why each path
# counts, or does not, goes to stderr. The rules:
#   - a path of one component: `platforms/apple/Sources/WestronUI/<Name>/`, its generated `<Name>+Contract.swift` and
#     `<Name>+Matrix.swift`, `platforms/apple/Sources/WestronCatalog/Components/<Name>Pages.swift`, its contract
#     `spec/components/<id>/` (`text-field` is `TextField`) → the entries `<Name>Pages.swift` declares. A component of
#     WestronUI without that page fails the script: every component has its catalog entry (Catalog.swift). A contract
#     without one is not implemented on Apple yet, and gives nothing. A component's page that holds code other pages
#     use (`FlowLayout` in ButtonPages.swift, used by the Checkbox and color pages) still gives only its own entries:
#     the other pages wait for the nightly run;
#   - a page of WestronCatalog's Foundations, or its root, that declares entries and shares nothing with other files
#     (every other type it declares is used by no other file of WestronCatalog, and it extends no type but
#     CatalogEntry) → those entries;
#   - anything else → nothing. Shared paths (tokens, the shared files of WestronUI, the catalog's host and its shared
#     pages, the audit test, tools/apple/, Package.swift, the workflows) touch every entry: the nightly full audit
#     (.github/workflows/accessibility-audit.yml) covers them, and it can be run by hand on a branch.
# The entry ids come from the sources: `static let <name> = CatalogEntry(id: "<id>", …)` in the pages, and the
# registry's `.<name>,` lines. An entry its page declares but the registry leaves out is not audited by anyone, so it
# is left out here too.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

ui=platforms/apple/Sources/WestronUI
catalog=platforms/apple/Sources/WestronCatalog
registry="$catalog/Catalog.swift"

note() { echo "audit-scope: $*" >&2; }

# The entries <file> declares, "<name> <id>" per line.
declared() {
  perl -0777 -ne 'while (/static\s+let\s+(\w+)\s*=\s*CatalogEntry\(\s*id:\s*"([^"]+)"/g) { print "$1 $2\n" }' "$1"
}

# The page of the component <Name>; fails when <Name> has code in WestronUI but no page.
component_page() {
  local name="$1" page="$catalog/Components/$1Pages.swift"
  if [ -f "$page" ]; then
    echo "$page"
  elif [ -d "$ui/$name" ] || [ -f "$ui/Generated/$name+Contract.swift" ]; then
    echo "audit-scope: the component $name has code in $ui but no catalog page $page;" \
      "add its entries (Catalog.swift) or teach this script its page" >&2
    return 1
  fi
}

# Whether the page <file> shares nothing with the rest of WestronCatalog (see the rules above).
self_contained() {
  local file="$1" type users
  # Captured rather than piped into `grep -q`, which may close the pipe early and fail it under pipefail.
  users="$(grep -E '^(public |internal )?extension ' "$file" | grep -vE 'extension CatalogEntry( |\{|$)' || true)"
  [ -z "$users" ] || return 1
  while IFS= read -r type; do
    users="$(grep -rlw --include='*.swift' "$type" "$catalog" | grep -vxF "$file" || true)"
    [ -z "$users" ] || return 1
  done < <(sed -nE 's/^(public |internal )?(final )?(struct|enum|class|actor|protocol) ([A-Za-z0-9_]+).*/\4/p' "$file")
}

pages=""
while IFS= read -r path || [ -n "$path" ]; do
  [ -n "$path" ] || continue
  page="" why="shared or outside the catalog"
  case "$path" in
    "$ui"/Generated/*+Contract.swift)
      name="${path##*/}"
      page="$(component_page "${name%+Contract.swift}")"
      ;;
    "$catalog"/Generated/ComponentMatrix+All.swift) ;;
    "$catalog"/Generated/*+Matrix.swift)
      name="${path##*/}"
      page="$(component_page "${name%+Matrix.swift}")"
      ;;
    "$ui"/Generated/* | "$ui"/Fonts/* | "$ui"/*.xcassets/*) ;;
    "$ui"/*/*)
      name="${path#"$ui"/}"
      page="$(component_page "${name%%/*}")"
      ;;
    "$catalog"/Components/*Pages.swift)
      page="$path"
      ;;
    spec/components/*/*)
      id="${path#spec/components/}"
      id="${id%%/*}"
      name="$(perl -pe 's/(?:^|-)(\w)/\u$1/g' <<< "$id")"
      page="$(component_page "$name")"
      [ -n "$page" ] || why="the contract $id has no catalog page: not implemented on Apple yet"
      ;;
    "$catalog"/Foundations/*.swift | "$catalog"/*.swift)
      if [ -f "$path" ] && [ -n "$(declared "$path")" ] && self_contained "$path"; then
        page="$path"
      fi
      ;;
  esac
  if [ -n "$page" ] && [ -f "$page" ]; then
    note "$path → $(declared "$page" | cut -d' ' -f2 | paste -sd, -)"
    pages+="$page"$'\n'
  elif [ -z "$page" ]; then
    note "$path → nothing on a pull request: $why"
  else
    note "$path → its page $page is gone: nothing"
  fi
done

# The ids of the pages' entries, in the registry's order.
ids=""
if [ -n "$pages" ]; then
  wanted="$(sort -u <<< "$pages" | sed '/^$/d' | while IFS= read -r page; do declared "$page"; done)"
  while IFS= read -r name; do
    id="$(awk -v name="$name" '$1 == name { print $2 }' <<< "$wanted")"
    if [ -n "$id" ]; then ids+="${ids:+,}$id"; fi
  done < <(sed -n '/static let entries: \[CatalogEntry\] = \[/,/^ *\]/p' "$registry" | sed -nE 's/^ *\.([A-Za-z0-9_]+),?$/\1/p')
  while IFS= read -r name; do
    grep -qE "^ *\.$name,?$" "$registry" || note "the entry $name is not in the registry ($registry), so it is not audited"
  done < <(cut -d" " -f1 <<< "$wanted")
fi
echo "$ids"
