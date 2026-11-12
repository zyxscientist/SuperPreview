#!/bin/sh
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_binary=$(mktemp "${TMPDIR:-/tmp}/stock-chart-tests.XXXXXX")
asset_test_binary=$(mktemp "${TMPDIR:-/tmp}/stock-chart-corporate-assets.XXXXXX")
trap 'rm -f "$test_binary" "$asset_test_binary"' EXIT
swiftc "$repo_dir/SuperPreview/Components/StockChart/StockChartData.swift" \
    "$repo_dir/SuperPreview/Components/StockChart/StockChartCorporateActions.swift" \
    "$repo_dir/Tests/StockChartDataTests.swift" -o "$test_binary"
"$test_binary"
swiftc -parse-as-library "$repo_dir/Tests/StockChartCorporateAssetTests.swift" -o "$asset_test_binary"
"$asset_test_binary" "$repo_dir"
