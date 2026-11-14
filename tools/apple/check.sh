#!/usr/bin/env bash
# Проверки Swift-части westron. Их же запускают CI и хук Stop агента.
#
#   tools/apple/check.sh package     swift build + swift test (macOS)
#   tools/apple/check.sh platforms   компиляция пакета для iOS и watchOS
#   tools/apple/check.sh catalog     сборка каталога и UI-тестов для iOS-симулятора и macOS
#   tools/apple/check.sh format      swift format lint без правок
#   tools/apple/check.sh fix-format  swift format с правкой файлов
#   tools/apple/check.sh all         всё, кроме fix-format
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
# shellcheck source=tools/apple/xcode-env.sh
source tools/apple/xcode-env.sh

swift_sources=(Package.swift platforms/apple)
min_ios="$(sed -n 's/.*\.iOS(\.v\([0-9]*\)).*/\1/p' Package.swift).0"
min_watchos="$(sed -n 's/.*\.watchOS(\.v\([0-9]*\)).*/\1/p' Package.swift).0"

package() {
  swift build
  swift test
}

platforms() {
  swift build --triple "arm64-apple-ios$min_ios" --sdk "$(xcrun --sdk iphoneos --show-sdk-path)"
  swift build --triple "arm64_32-apple-watchos$min_watchos" --sdk "$(xcrun --sdk watchos --show-sdk-path)"
}

catalog() {
  local destination log=.build/logs/catalog-build.log
  mkdir -p .build/logs
  for destination in "generic/platform=iOS Simulator" "platform=macOS,arch=$(uname -m)"; do
    echo "== каталог: $destination"
    if ! xcodebuild -project platforms/apple/Catalog/Catalog.xcodeproj -scheme Catalog -destination "$destination" \
      -derivedDataPath .build/xcode/catalog build-for-testing > "$log" 2>&1; then
      grep -E "error:|warning:|FAILED" "$log" | grep -v "\[MT\]" | tail -40 >&2
      echo "check.sh: сборка каталога не удалась ($destination), лог: $log" >&2
      return 1
    fi
  done
}

format() {
  swift format lint --strict --recursive --parallel "${swift_sources[@]}"
}

fix_format() {
  swift format format --in-place --recursive --parallel "${swift_sources[@]}"
}

case "${1:-}" in
  package) package ;;
  platforms) platforms ;;
  catalog) catalog ;;
  format) format ;;
  fix-format) fix_format ;;
  all) format; package; platforms; catalog ;;
  *) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
