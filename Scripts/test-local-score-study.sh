#!/bin/sh
set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
project_directory=$(dirname "$script_directory")
test_directory=$(mktemp -d "${TMPDIR:-/tmp}/pitchee-local-score-study.XXXXXX")
trap 'rm -rf "$test_directory"' EXIT HUP INT TERM

xcrun swiftc -parse-as-library -swift-version 5 \
    -target "$(uname -m)-apple-macosx14.0" \
    "$project_directory/PitcheeApp/Interop/Core/AnalysisResult.swift" \
    "$project_directory/PitcheeApp/VoiceScoring.swift" \
    "$project_directory/PitcheeApp/LocalDiagnostics.swift" \
    "$project_directory/PitcheeApp/PrivateAppStorage.swift" \
    "$project_directory/PitcheeApp/LocalDiagnosticsStore.swift" \
    "$project_directory/PitcheeApp/LocalScoreStudy.swift" \
    "$project_directory/PitcheeApp/LocalScoreStudyStore.swift" \
    "$project_directory/PitcheeApp/ScoreStudyEvaluator.swift" \
    "$project_directory/Tests/LocalScoreStudyTests.swift" \
    -o "$test_directory/local-score-study-tests"

"$test_directory/local-score-study-tests"
