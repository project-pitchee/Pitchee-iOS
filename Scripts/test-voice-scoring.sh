#!/bin/sh
set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
project_directory=$(dirname "$script_directory")
test_directory=$(mktemp -d "${TMPDIR:-/tmp}/pitchee-voice-scoring.XXXXXX")
trap 'rm -rf "$test_directory"' EXIT HUP INT TERM

xcrun clang++ -std=c++17 \
    -I "$project_directory/Dependencies/PitcheeCore/src" \
    -I "$project_directory/Dependencies/PitcheeCore/include" \
    "$project_directory/Dependencies/PitcheeCore/src/scoring.cpp" \
    "$project_directory/Tests/Voice/VoiceScoringReference.cpp" \
    -o "$test_directory/scoring-reference"
"$test_directory/scoring-reference" > "$test_directory/reference.tsv"

xcrun swiftc -parse-as-library -swift-version 5 \
    "$project_directory/PitcheeApp/Interop/Core/AnalysisResult.swift" \
    "$project_directory/PitcheeApp/Analysis/VoiceScoring.swift" \
    "$project_directory/Tests/Voice/VoiceScoringTests.swift" \
    -o "$test_directory/voice-scoring-tests"

"$test_directory/voice-scoring-tests" "$test_directory/reference.tsv"
