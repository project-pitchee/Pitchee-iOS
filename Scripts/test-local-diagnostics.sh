#!/bin/sh
set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
project_directory=$(dirname "$script_directory")
test_directory=$(mktemp -d "${TMPDIR:-/tmp}/pitchee-local-diagnostics.XXXXXX")
trap 'rm -rf "$test_directory"' EXIT HUP INT TERM

xcrun swiftc -parse-as-library -swift-version 5 \
    -target "$(uname -m)-apple-macosx14.0" \
    "$project_directory/PitcheeApp/LocalDiagnostics.swift" \
    "$project_directory/PitcheeApp/PrivateAppStorage.swift" \
    "$project_directory/PitcheeApp/LocalDiagnosticsStore.swift" \
    "$project_directory/Tests/LocalDiagnosticsTests.swift" \
    -o "$test_directory/local-diagnostics-tests"

"$test_directory/local-diagnostics-tests"
