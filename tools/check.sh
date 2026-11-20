#!/usr/bin/env bash
# Checks of the tools/ package and the checks it runs over the repository. CI runs the same script on Linux,
# and the agent's Stop hook runs it on macOS with the Xcode from .xcode-version.
#
#   tools/check.sh            every step below, in this order: build and test tools/ (tools), the raw-values lint
#                             (raw-values), generate --check (generate), tokens check (tokens) and contrast
#                             (contrast), icons check (icons), spec check (spec), the API parity lint (api-parity,
#                             after spec check, since it reads the contracts)
#   tools/check.sh STEP …     those steps only, still in that order: the Stop hook runs the ones the changes touch
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

all_steps="tools raw-values generate tokens contrast icons spec api-parity"
for step in "$@"; do
  if [[ " $all_steps " != *" $step "* ]]; then
    echo "tools/check.sh: no step \"$step\"; the steps: $all_steps" >&2
    exit 2
  fi
done
selected=" ${*:-$all_steps} "
selected() { [[ "$selected" == *" $1 "* ]]; }

if [ "$(uname -s)" = Darwin ]; then
  # shellcheck source=tools/apple/xcode-env.sh
  source tools/apple/xcode-env.sh
fi

if selected tools; then
  echo "== tools: build and test"
  swift build --package-path tools
  swift test --package-path tools
fi
if selected raw-values; then
  echo "== raw-values lint"
  tools/westron lint raw-values
fi
if selected generate; then
  echo "== generate --check"
  tools/westron generate --check
fi
if selected tokens; then
  echo "== tokens check"
  tools/westron tokens check
fi
if selected contrast; then
  echo "== tokens contrast (WCAG 2, every theme)"
  tools/westron tokens contrast
fi
if selected icons; then
  echo "== icons check"
  tools/westron icons check
fi
if selected spec; then
  echo "== spec check"
  tools/westron spec check
fi
if selected api-parity; then
  echo "== api-parity lint"
  tools/westron lint api-parity
fi
