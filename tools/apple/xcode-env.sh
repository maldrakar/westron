# shellcheck shell=bash
# Loaded with `source`: sets DEVELOPER_DIR to the Xcode from .xcode-version.
#
# If DEVELOPER_DIR is already set (CI does this), it checks that this is the right version. Otherwise it looks
# for Xcode with this version in /Applications. It does not touch xcode-select.

westron_root="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/../.." && pwd)"
westron_xcode_pin="$(tr -d '[:space:]' < "$westron_root/.xcode-version")"

# $1 is the path to Contents/Developer. The version comes from version.plist in the Xcode bundle.
westron_xcode_matches() {
  local version
  version="$(plutil -extract CFBundleShortVersionString raw "$1/../version.plist" 2>/dev/null)" || return 1
  [ "$version" = "$westron_xcode_pin" ]
}

if [ -n "${DEVELOPER_DIR:-}" ]; then
  if ! westron_xcode_matches "$DEVELOPER_DIR"; then
    echo "xcode-env: DEVELOPER_DIR=$DEVELOPER_DIR is not Xcode $westron_xcode_pin from .xcode-version" >&2
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
    echo "xcode-env: Xcode $westron_xcode_pin (.xcode-version) not found in /Applications" >&2
    return 1 2>/dev/null || exit 1
  fi
fi
