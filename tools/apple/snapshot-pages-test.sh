#!/usr/bin/env bash
# Tests tools/apple/snapshot-pages.swift, the comparison behind tools/apple/snapshot-matrix.sh compare, check and
# record, on tiny fixture images: macOS only (it reads PNGs with ImageIO), so tools/check.sh runs it on a Mac (step
# pages) and skips it on Linux, and CI's job `snapshots` runs it before it checks the matrix. About 20 s, most of it
# the compile.
#
#   tools/apple/snapshot-pages-test.sh
#
# Cases: a picture the render's manifest marks not compared (a supplement's `notCompared` on this OS) that differs
# does not fail compare and is counted and listed with its reason; one whose size changed, that is missing, or that the
# references do not hold still fails; an ordinary picture that differs still fails; --strict compares every picture; a
# mark in either directory's manifest counts; sync keeps an existing not-compared reference of the same size as it
# was, byte for byte, and replaces one whose size changed; index names the mark on the review page.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
# shellcheck source=tools/apple/xcode-env.sh
source tools/apple/xcode-env.sh

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
binary="$work/snapshot-pages"
xcrun --sdk macosx swiftc -o "$binary" tools/apple/snapshot-pages.swift
failures=0

fail() {
  echo "snapshot-pages-test: FAIL: $*" >&2
  failures=$((failures + 1))
}
ok() { echo "snapshot-pages-test: ok: $*"; }

# Little-endian bytes as printf escapes.
le() {
  local value="$1" count="$2" i
  for ((i = 0; i < count; i++)); do printf '\\x%02x' $(((value >> (8 * i)) & 255)); done
}

# png <file> <r> <g> <b> [<width>]: a PNG of <width> (a multiple of 4, default 4) by 4 pixels in one color, through a
# 24-bit BMP that sips converts.
png() {
  local file="$1" r="$2" g="$3" b="$4" width="${5:-4}" height=4 pixels="" i
  local data=$((width * height * 3))
  for ((i = 0; i < width * height; i++)); do pixels+="$(printf '\\x%02x\\x%02x\\x%02x' "$b" "$g" "$r")"; done
  # shellcheck disable=SC2059 # the format is the escapes built above
  printf "BM$(le $((54 + data)) 4)$(le 0 4)$(le 54 4)$(le 40 4)$(le "$width" 4)$(le "$height" 4)$(le 1 2)$(le 24 2)$(le 0 4)$(le "$data" 4)$(le 2835 4)$(le 2835 4)$(le 0 4)$(le 0 4)$pixels" \
    > "$work/fixture.bmp"
  sips -s format png "$work/fixture.bmp" --out "$file" > /dev/null
}

plain=button.plain.light.png
glass=button.glass.light.png
reason="The glass varies from one render to the next."

# A render's manifest: the generated sheet `plain` and the supplement `glass`, marked not compared.
manifest() {
  cat > "$1/matrix.json" << EOF
{"platform": "ios", "os": "iOS test", "device": "test", "scale": 1, "pinned": [],
 "captures": [{"name": "light", "theme": "light", "textSize": "large", "arguments": []}],
 "components": [{"component": "button", "columns": "variant", "notes": [], "groups": [
   {"id": "contract", "title": "from the contract", "supplement": false, "combinations": 1, "sheets": [
     {"id": "plain", "title": "plain", "fixed": [], "cells": 1,
      "images": {"light": [{"file": "$plain", "cells": 1, "found": 1, "fits": true, "squeezed": 0}]}}]},
   {"id": "glass", "title": "on glass", "supplement": true, "note": "A test.", "notCompared": "$reason",
    "combinations": 1, "sheets": [
     {"id": "glass", "title": "on glass", "fixed": [], "cells": 1,
      "images": {"light": [{"file": "$glass", "cells": 1, "found": 1, "fits": true, "squeezed": 0}]}}]}]}]}
EOF
}

# references: as recorded, no manifest. render: the same plain picture, the glass in another color.
mkdir -p "$work/references" "$work/render"
png "$work/references/$plain" 200 0 0
png "$work/references/$glass" 0 0 200
png "$work/render/$plain" 200 0 0
png "$work/render/$glass" 0 200 0
manifest "$work/render"

# variant <name> <command…>: a copy of the render, changed by the command run in it.
variant() {
  local name="$1"
  shift
  cp -R "$work/render" "$work/$name"
  (cd "$work/$name" && "$@")
}

# expect <status> <pattern> <case> <compare arguments…>: compare exits <status> and prints a line matching <pattern>.
expect() {
  local status="$1" pattern="$2" case="$3" got=0 output
  shift 3
  output="$("$binary" compare "$@" 2>&1)" || got=$?
  if [ "$got" != "$status" ]; then
    fail "$case: exit $got, expected $status; output:"$'\n'"$output"
  elif ! grep -qE -- "$pattern" <<< "$output"; then
    fail "$case: no line matching \"$pattern\"; output:"$'\n'"$output"
  else
    ok "$case"
  fi
}

expect 0 "^snapshot-matrix compare: 0 changed, 0 added, 0 removed, 1 unchanged .*; 1 not compared$" \
  "a not-compared picture that differs does not fail, and is counted" \
  "$work/references" "$work/render" "$work/out" --labels reference,new
grep -qF "not compared (1, button): $reason" <<< "$("$binary" compare "$work/references" "$work/render" "$work/out")" \
  && ok "its reason is printed" || fail "the reason is not printed"
if grep -qF "Not compared (1)" "$work/out/index.html" && grep -qF "$reason" "$work/out/index.html" \
  && grep -qF "after/$glass" "$work/out/index.html" && [ -f "$work/out/after/$glass" ]; then
  ok "the report lists it with its reason and the new picture"
else
  fail "the report does not list the not-compared picture with its reason and the new picture"
fi

variant plain-changed png "$plain" 0 200 0
expect 1 "^changed: $plain " "an ordinary picture that differs still fails" \
  "$work/references" "$work/plain-changed" "$work/out"

variant glass-missing rm "$glass"
expect 1 "^removed: $glass$" "a missing not-compared picture fails" \
  "$work/references" "$work/glass-missing" "$work/out"

mkdir -p "$work/references-without-glass"
cp "$work/references/$plain" "$work/references-without-glass/"
expect 1 "^added: $glass$" "a not-compared picture the references do not hold fails" \
  "$work/references-without-glass" "$work/render" "$work/out"

variant glass-wider png "$glass" 0 200 0 8
expect 1 "^changed: $glass \(the size changed: 4 × 4 → 8 × 4\)" "a not-compared picture whose size changed fails" \
  "$work/references" "$work/glass-wider" "$work/out"

expect 1 "^changed: $glass " "--strict compares it pixel by pixel" \
  "$work/references" "$work/render" "$work/out" --strict

expect 0 "1 not compared$" "a mark in the first directory's manifest counts too" \
  "$work/render" "$work/references" "$work/out"

# sync: the not-compared reference of the same size stays as it was; a changed ordinary one is replaced.
cp -R "$work/references" "$work/recorded"
before_glass="$(shasum "$work/recorded/$glass" | cut -d' ' -f1)"
output="$("$binary" sync "$work/plain-changed" "$work/recorded")"
if [ "$(shasum "$work/recorded/$glass" | cut -d' ' -f1)" = "$before_glass" ] \
  && cmp -s "$work/recorded/$plain" "$work/plain-changed/$plain" \
  && grep -qF "1 not compared kept as they were" <<< "$output"; then
  ok "sync keeps a not-compared reference of the same size and replaces a changed ordinary one"
else
  fail "sync: $output"
fi
"$binary" sync "$work/glass-wider" "$work/recorded" > /dev/null
cmp -s "$work/recorded/$glass" "$work/glass-wider/$glass" \
  && ok "sync replaces a not-compared reference whose size changed" \
  || fail "sync kept a not-compared reference whose size changed"
rm -rf "$work/recorded"
mkdir -p "$work/recorded"
"$binary" sync "$work/render" "$work/recorded" > /dev/null
[ -f "$work/recorded/$glass" ] && ok "sync adds a new not-compared reference" \
  || fail "sync did not add a new not-compared reference"

if "$binary" index "$work/render" > /dev/null && grep -qF "Not compared on iOS" "$work/render/index.html" \
  && grep -qF "$reason" "$work/render/index.html"; then
  ok "the review page names the mark and its reason"
else
  fail "the review page does not name the mark"
fi

if [ "$failures" -gt 0 ]; then
  echo "snapshot-pages-test: $failures failed" >&2
  exit 1
fi
echo "snapshot-pages-test: all passed"
