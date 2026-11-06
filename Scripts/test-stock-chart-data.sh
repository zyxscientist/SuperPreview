#!/bin/sh
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_binary=$(mktemp "${TMPDIR:-/tmp}/stock-chart-tests.XXXXXX")
trap 'rm -f "$test_binary"' EXIT
swiftc "$repo_dir/SuperPreview/Components/StockChart/StockChartData.swift" "$repo_dir/Tests/StockChartDataTests.swift" -o "$test_binary"
"$test_binary"
