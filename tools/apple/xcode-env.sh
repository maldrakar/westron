# shellcheck shell=bash
# Подключается через `source`: выставляет DEVELOPER_DIR на Xcode из .xcode-version.
#
# Если DEVELOPER_DIR уже задан (так делает CI), проверяется, что это нужная версия. Иначе ищется Xcode
# в /Applications с этой версией. xcode-select при этом не трогается.

westron_root="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/../.." && pwd)"
westron_xcode_pin="$(tr -d '[:space:]' < "$westron_root/.xcode-version")"

# $1 — путь к Contents/Developer. Версия берётся из version.plist бандла Xcode.
westron_xcode_matches() {
  local version
  version="$(plutil -extract CFBundleShortVersionString raw "$1/../version.plist" 2>/dev/null)" || return 1
  [ "$version" = "$westron_xcode_pin" ]
}

if [ -n "${DEVELOPER_DIR:-}" ]; then
  if ! westron_xcode_matches "$DEVELOPER_DIR"; then
    echo "xcode-env: DEVELOPER_DIR=$DEVELOPER_DIR — не Xcode $westron_xcode_pin из .xcode-version" >&2
    return 1 2>/dev/null || exit 1
  fi
else
  for westron_candidate in /Applications/Xcode*.app/Contents/Developer; do
    if westron_xcode_matches "$westron_candidate"; then
      export DEVELOPER_DIR="$westron_candidate"
      break
    fi
  done
  if [ -z "${DEVELOPER_DIR:-}" ]; then
    echo "xcode-env: не найден Xcode $westron_xcode_pin (.xcode-version) в /Applications" >&2
    return 1 2>/dev/null || exit 1
  fi
fi
