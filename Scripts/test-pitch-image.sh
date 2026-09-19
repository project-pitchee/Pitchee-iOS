#!/bin/sh

set -eu
script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
project_directory=$(dirname "$script_directory")
test_directory=$(mktemp -d "${TMPDIR:-/tmp}/pitchee-pitch-image.XXXXXX")
trap 'rm -rf "$test_directory"' EXIT HUP INT TERM

xcrun swiftc -parse-as-library \
    "$project_directory/PitcheeApp/Interop/Core/AnalysisResult.swift" \
    "$project_directory/PitcheeApp/PitchTimeline.swift" \
    "$project_directory/PitcheeApp/LivePitchChartView.swift" \
    "$project_directory/Tests/PitchTimelineTests.swift" \
    -o "$test_directory/pitch-image-tests"
"$test_directory/pitch-image-tests" "${1:-/tmp/pitchee-pitch-export-preview.png}"
