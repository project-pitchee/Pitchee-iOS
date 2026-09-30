#!/bin/sh
set -eu
script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
project_directory=$(dirname "$script_directory")
test_directory=$(mktemp -d "${TMPDIR:-/tmp}/pitchee-practice.XXXXXX")
trap 'rm -rf "$test_directory"' EXIT HUP INT TERM
xcrun swiftc -parse-as-library -swift-version 5 -target "$(uname -m)-apple-macosx14.0" \
    "$project_directory/PitcheeApp/Interop/Core/AnalysisResult.swift" \
    "$project_directory/PitcheeApp/VoiceScoring.swift" \
    "$project_directory/PitcheeApp/PracticeData.swift" \
    "$project_directory/PitcheeApp/RecordingAssessment.swift" \
    "$project_directory/PitcheeApp/InsightsData.swift" \
    "$project_directory/PitcheeApp/PrivateAppStorage.swift" \
    "$project_directory/Tests/PracticeTests.swift" \
    -o "$test_directory/practice-tests"
"$test_directory/practice-tests"
xcrun swiftc -parse-as-library -swift-version 5 -module-name PracticeMigrationTests -D LEGACY_PRACTICE_SCHEMA \
    -target "$(uname -m)-apple-macosx14.0" \
    "$project_directory/Tests/Fixtures/RecordingAssessmentBeforePractice.swift" \
    "$project_directory/Tests/PracticeMigrationTests.swift" \
    -o "$test_directory/create-old-store"
"$test_directory/create-old-store" "$test_directory/history.store"
xcrun swiftc -parse-as-library -swift-version 5 -module-name PracticeMigrationTests \
    -target "$(uname -m)-apple-macosx14.0" \
    "$project_directory/PitcheeApp/Interop/Core/AnalysisResult.swift" \
    "$project_directory/PitcheeApp/VoiceScoring.swift" \
    "$project_directory/PitcheeApp/PracticeData.swift" \
    "$project_directory/PitcheeApp/RecordingAssessment.swift" \
    "$project_directory/Tests/PracticeMigrationTests.swift" \
    -o "$test_directory/migrate-store"
"$test_directory/migrate-store" "$test_directory/history.store"
"$test_directory/migrate-store" "$test_directory/history.store"
xcrun swiftc -parse-as-library -swift-version 5 \
    "$project_directory/PitcheeApp/Interop/Core/AnalysisResult.swift" \
    "$project_directory/PitcheeApp/RecordingStatistics.swift" \
    "$project_directory/Tests/RecordingQualityAudioTests.swift" \
    -o "$test_directory/audio-quality-tests"
"$test_directory/audio-quality-tests"
