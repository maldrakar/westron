# shellcheck shell=bash
# Loaded with `source` after xcode-env.sh: finds and boots the iOS simulator the catalog runs on.
#
#   udid="$(westron_simulator_udid "iPhone 17")" || exit 1
#
# prints the UDID of a booted simulator, or fails with a message. Each step fails the function explicitly: a function
# called inside $(...) does not stop at a failing command under `set -e` in bash 3.2.

# The newest iOS runtime with this device, no newer than the SDK of the current Xcode.
westron_simulator_udid() {
  local device="$1" sdk_version devices udid
  sdk_version="$(xcrun --sdk iphonesimulator --show-sdk-version)" || return 1
  devices="$(xcrun simctl list devices available -j)" || return 1
  # jq ships with macOS. Versions become [major, minor, patch] and compare as arrays.
  udid="$(jq -r --arg device "$device" --arg sdk "$sdk_version" '
    def version: split(".") | map(tonumber) | (. + [0, 0, 0])[0:3];
    ($sdk | version) as $max
    | [.devices | to_entries[]
        | (.key | capture("SimRuntime\\.iOS-(?<v>[0-9]+(-[0-9]+)*)$").v | gsub("-"; ".") | version) as $v
        | .value[] | select(.name == $device) | {udid, v: $v}]
    | (map(select(.v <= $max))) as $fits
    | (if ($fits | length) > 0 then $fits else . end)
    | sort_by(.v) | last | .udid // empty
  ' <<< "$devices")" || return 1
  if [ -z "$udid" ]; then
    echo "no simulator \"$device\"; list the available ones: xcrun simctl list devices available" >&2
    return 1
  fi
  if ! xcrun simctl bootstatus "$udid" -b > /dev/null; then
    echo "simulator \"$device\" ($udid) did not boot" >&2
    return 1
  fi
  echo "$udid"
}
