#!/usr/bin/env bash
# Checks of the tools/ package and the checks it runs over the repository. CI runs the same script on Linux,
# and the agent's Stop hook runs it on macOS with the Xcode from .xcode-version.
#
#   tools/check.sh    build and test tools/, the raw-values lint, generate --check, tokens check and contrast,
#                     icons check
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
if [ "$(uname -s)" = Darwin ]; then
  # shellcheck source=tools/apple/xcode-env.sh
  source tools/apple/xcode-env.sh
fi

echo "== tools: build and test"
swift build --package-path tools
swift test --package-path tools
echo "== raw-values lint"
tools/westron lint raw-values
echo "== generate --check"
tools/westron generate --check
echo "== tokens check"
tools/westron tokens check
echo "== tokens contrast (WCAG 2, every theme)"
tools/westron tokens contrast
echo "== icons check"
tools/westron icons check
