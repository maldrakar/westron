#!/usr/bin/env bash
# Скриншот записи каталога на iOS-симуляторе или macOS — «глаза» агента и поверхность ревью.
#
#   tools/apple/catalog-screenshot.sh <ios|macos> [--entry ID] [--appearance light|dark]
#                                     [--dynamic-type РАЗМЕР] [--device "iPhone 17"] [--out ФАЙЛ.png]
#
# Собирает каталог (инкрементально), запускает UI-тест CatalogScreenshotTests и печатает абсолютный путь к PNG.
# По умолчанию PNG ложится в .build/screenshots/. Лог xcodebuild — в .build/logs/.
# macOS: один раз на машине нужно включить Automation Mode (см. platforms/apple/README.md).
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
# shellcheck source=tools/apple/xcode-env.sh
source tools/apple/xcode-env.sh

usage() { sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

platform="${1:-}"
[ "$platform" = ios ] || [ "$platform" = macos ] || usage
shift
entry=environment appearance="" dynamic_type="" device="${WESTRON_SIM_DEVICE:-iPhone 17}" out=""
while [ $# -gt 0 ]; do
  case "$1" in
    --entry) entry="$2"; shift 2 ;;
    --appearance) appearance="$2"; shift 2 ;;
    --dynamic-type) dynamic_type="$2"; shift 2 ;;
    --device) device="$2"; shift 2 ;;
    --out) out="$2"; shift 2 ;;
    *) usage ;;
  esac
done

name="$platform-$entry${appearance:+-$appearance}${dynamic_type:+-$dynamic_type}"
out="${out:-.build/screenshots/$name.png}"
case "$out" in /*) ;; *) out="$root/$out" ;; esac
mkdir -p "$(dirname "$out")" .build/logs
rm -f "$out"
log=".build/logs/catalog-$name.log"

if [ "$platform" = ios ]; then
  # Самая новая среда iOS с этим устройством, не новее SDK текущего Xcode.
  sdk_version="$(xcrun --sdk iphonesimulator --show-sdk-version)"
  udid="$(xcrun simctl list devices available -j | node -e '
    const [device, sdk] = process.argv.slice(1);
    const num = (v) => v.split(".").map(Number);
    const cmp = (a, b) => { for (let i = 0; i < 3; i++) { const d = (a[i] ?? 0) - (b[i] ?? 0); if (d) return d; } return 0; };
    const data = JSON.parse(require("fs").readFileSync(0, "utf8"));
    const found = [];
    for (const [runtime, list] of Object.entries(data.devices)) {
      const m = runtime.match(/SimRuntime\.iOS-(\d+(?:-\d+)*)$/);
      if (!m) continue;
      for (const d of list) if (d.name === device) found.push({ udid: d.udid, version: num(m[1].replaceAll("-", ".")) });
    }
    const fits = found.filter((f) => cmp(f.version, num(sdk)) <= 0);
    const pick = (fits.length ? fits : found).sort((a, b) => cmp(b.version, a.version))[0];
    if (pick) console.log(pick.udid);
  ' "$device" "$sdk_version")"
  if [ -z "$udid" ]; then
    echo "catalog-screenshot: нет симулятора «$device»; доступные: xcrun simctl list devices available" >&2
    exit 1
  fi
  xcrun simctl bootstatus "$udid" -b > /dev/null
  # Одинаковая строка состояния на всех скриншотах.
  xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 \
    --wifiBars 3 --cellularMode active --cellularBars 4 --dataNetwork wifi
  destination="id=$udid"
else
  destination="platform=macOS,arch=$(uname -m)"
fi

xcodebuild_args=(-project platforms/apple/Catalog/Catalog.xcodeproj -scheme Catalog -destination "$destination"
  -derivedDataPath .build/xcode/catalog)

if ! xcodebuild "${xcodebuild_args[@]}" build-for-testing > "$log" 2>&1; then
  grep -E "error:|BUILD FAILED" "$log" | head -20 >&2 || true
  echo "catalog-screenshot: сборка не удалась, лог: $log" >&2
  exit 1
fi

screenshot_failed() {
  grep -E ": error: |Underlying Error|automation mode" "$log" | grep -v "\[MT\]" | head -20 >&2 || true
  echo "catalog-screenshot: скриншот не получен, лог: $log" >&2
  exit 1
}

export TEST_RUNNER_WESTRON_ENTRY="$entry"
[ -n "$appearance" ] && export TEST_RUNNER_WESTRON_APPEARANCE="$appearance"
[ -n "$dynamic_type" ] && export TEST_RUNNER_WESTRON_DYNAMIC_TYPE="$dynamic_type"

# Раннер не пишет файл сам (на macOS он в песочнице): PNG — вложение в результате теста.
results=".build/xcode/results/$name.xcresult"
attachments=".build/xcode/results/$name-attachments"
rm -rf "$results" "$attachments"
mkdir -p .build/xcode/results

xcodebuild "${xcodebuild_args[@]}" test-without-building -resultBundlePath "$results" \
  -only-testing:CatalogUITests/CatalogScreenshotTests/testScreenshot >> "$log" 2>&1 || screenshot_failed
xcrun xcresulttool export attachments --path "$results" --output-path "$attachments" \
  --filter "westron-screenshot*" >> "$log" 2>&1 || screenshot_failed
png="$(find "$attachments" -name '*.png' | head -1)"
[ -n "$png" ] || screenshot_failed
mv "$png" "$out"

echo "$out"
