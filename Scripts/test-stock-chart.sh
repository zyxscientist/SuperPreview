#!/usr/bin/env bash
# Run chart data checks, then the UI chart suite in the 402/440 pt light/dark matrix.
# Usage: Scripts/test-stock-chart.sh
# Narrow the matrix, e.g. DEVICE_NAMES='iPhone 17 Pro' APPEARANCES=light \
#   FILTER='StockDetailChartUITests/testPeriodPanPinchAndLongPress' Scripts/test-stock-chart.sh
# DEVICE_NAMES accepts comma-separated simulator names; FILTER is a test class or class/method.
# RESULTS_DIR controls the xcresult output location. Bundles retain screenshots on success/failure.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULTS_DIR="${RESULTS_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/superpreview-chart-results.XXXXXX")}"
RUNTIME="${RUNTIME:-com.apple.CoreSimulator.SimRuntime.iOS-27-0}"
FILTER="${FILTER:-StockDetailChartUITests}"
DEVICE_NAMES="${DEVICE_NAMES:-iPhone 17 Pro,iPhone 17 Pro Max}"
APPEARANCES="${APPEARANCES:-light dark}"

"$ROOT_DIR/Scripts/test-stock-chart-data.sh"
mkdir -p "$RESULTS_DIR"

find_device() {
    DEVICE_NAME="$1" RUNTIME_ID="$RUNTIME" /usr/bin/python3 -c '
import json, os, subprocess
items = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "-j"]))
for item in items.get("devices", {}).get(os.environ["RUNTIME_ID"], []):
    if item.get("name") == os.environ["DEVICE_NAME"] and item.get("isAvailable"):
        print(item["udid"])
        break
'
}

run_case() {
    local name="$1" appearance="$2" udid width bundle
    case "$name" in
        'iPhone 17 Pro') width=402 ;;
        'iPhone 17 Pro Max') width=440 ;;
        *) echo "Unsupported device: $name (expected iPhone 17 Pro or iPhone 17 Pro Max)" >&2; return 1 ;;
    esac
    udid="$(find_device "$name")"
    if [[ -z "$udid" ]]; then
        echo "No available $name on $RUNTIME" >&2
        return 1
    fi
    xcrun simctl boot "$udid" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$udid" -b >/dev/null
    xcrun simctl ui "$udid" appearance "$appearance"
    xcrun simctl ui "$udid" content_size large
    bundle="$RESULTS_DIR/${name// /-}-${appearance}.xcresult"
    echo "Testing $name · $appearance · ${width}pt · $FILTER"
    TRADE_EXPECTED_VIEWPORT_WIDTH="$width" xcodebuild \
        -project "$ROOT_DIR/SuperPreview.xcodeproj" \
        -scheme SuperPreview -testPlan SuperPreviewLayout \
        -disableAutomaticPackageResolution \
        -destination "platform=iOS Simulator,id=$udid" \
        -resultBundlePath "$bundle" \
        "-only-testing:SuperPreviewUITests/$FILTER" \
        CODE_SIGNING_ALLOWED=NO test
}

IFS=',' read -r -a devices <<< "$DEVICE_NAMES"
read -r -a appearances <<< "$APPEARANCES"
failed=0
for device in "${devices[@]}"; do
    # Trim whitespace around comma-separated names without changing internal spaces.
    device="${device#"${device%%[![:space:]]*}"}"
    device="${device%"${device##*[![:space:]]}"}"
    for appearance in "${appearances[@]}"; do
        case "$appearance" in light|dark) ;; *) echo "Unsupported appearance: $appearance" >&2; exit 1 ;; esac
        run_case "$device" "$appearance" || failed=1
    done
done
printf 'Result bundles: %s\n' "$RESULTS_DIR"
if [[ "$failed" -ne 0 ]]; then
    echo 'One or more stock chart UI cases failed.' >&2
    exit 1
fi
echo 'All selected stock chart UI cases passed.'
