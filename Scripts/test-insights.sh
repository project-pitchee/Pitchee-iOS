#!/bin/sh
set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
project_directory=$(dirname "$script_directory")
test_directory=$(mktemp -d "${TMPDIR:-/tmp}/pitchee-insights.XXXXXX")
trap 'rm -rf "$test_directory"' EXIT HUP INT TERM

xcrun swiftc -parse-as-library -swift-version 5 \
    -target "$(uname -m)-apple-macosx14.0" \
    "$project_directory/PitcheeApp/Interop/Core/AnalysisResult.swift" \
    "$project_directory/PitcheeApp/Analysis/VoiceScoring.swift" \
    "$project_directory/PitcheeApp/Practice/PracticeData.swift" \
    "$project_directory/PitcheeApp/Analysis/RecordingAssessment.swift" \
    "$project_directory/Tests/Fixtures/InsightsThemeSupport.swift" \
    "$project_directory/PitcheeApp/Insights/InsightsData.swift" \
    "$project_directory/Tests/Insights/InsightsDataTests.swift" \
    -o "$test_directory/insights-tests"

"$test_directory/insights-tests"
