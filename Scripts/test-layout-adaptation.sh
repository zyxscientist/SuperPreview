#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/SuperPreview.xcodeproj"
SCHEME="SuperPreview"
RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-26-5"
RESULTS_DIR="${RESULTS_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/superpreview-layout-results.XXXXXX")}"

find_device() {
    local device_name="$1"
    DEVICE_NAME="$device_name" RUNTIME_ID="$RUNTIME" \
        /usr/bin/python3 -c '
import json
import os
import sys

import subprocess

data = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "-j"]))
name = os.environ["DEVICE_NAME"]
runtime = os.environ["RUNTIME_ID"]
for device in data.get("devices", {}).get(runtime, []):
    if device.get("name") == name and device.get("isAvailable"):
        print(device["udid"])
        break
'
}

run_case() {
    local device_name="$1"
    local appearance="$2"
    local expected_width="$3"
    local udid
    udid="$(find_device "$device_name")"

    if [[ -z "$udid" ]]; then
        echo "No available $device_name on iOS 26.5" >&2
        return 1
    fi

    xcrun simctl boot "$udid" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$udid" -b >/dev/null
    xcrun simctl ui "$udid" appearance "$appearance"
    xcrun simctl ui "$udid" content_size large

    local result_bundle="$RESULTS_DIR/${device_name// /-}-${appearance}.xcresult"
    echo "Testing $device_name · $appearance · ${expected_width}pt"
    TRADE_EXPECTED_VIEWPORT_WIDTH="$expected_width" \
        xcodebuild \
            -project "$PROJECT_PATH" \
            -scheme "$SCHEME" \
            -testPlan SuperPreviewLayout \
            -destination "platform=iOS Simulator,id=$udid" \
            -resultBundlePath "$result_bundle" \
            CODE_SIGNING_ALLOWED=NO \
            test
}

mkdir -p "$RESULTS_DIR"
failed=0

run_case "iPhone 17 Pro" light 402 || failed=1
run_case "iPhone 17 Pro" dark 402 || failed=1
run_case "iPhone 17 Pro Max" light 440 || failed=1
run_case "iPhone 17 Pro Max" dark 440 || failed=1

echo "Result bundles: $RESULTS_DIR"
if [[ "$failed" -ne 0 ]]; then
    echo "One or more layout matrix cases failed." >&2
    exit 1
fi

echo "All iPhone 17 Pro / Pro Max portrait layout cases passed."
