#!/bin/sh

set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
project_directory=$(dirname "$script_directory")
runtime_directory="$project_directory/Dependencies/Artifacts/ONNXRuntime"
framework_directory="$runtime_directory/onnxruntime.xcframework/macos-arm64_x86_64"

if [ ! -f "$framework_directory/onnxruntime.framework/onnxruntime" ]; then
    echo "Install ONNX Runtime with Scripts/bootstrap-native-dependencies.sh first." >&2
    exit 1
fi

test_directory=$(mktemp -d "${TMPDIR:-/tmp}/pitchee-live-f0.XXXXXX")
trap 'rm -rf "$test_directory"' EXIT HUP INT TERM

cmake -S "$project_directory/Dependencies/PitcheeCore" -B "$test_directory/native" \
    -DCMAKE_BUILD_TYPE=Release \
    -DPITCHEE_BUILD_SHARED=OFF \
    -DPITCHEE_BUILD_CLI=OFF \
    -DPITCHEE_BUILD_TESTS=OFF \
    -DPITCHEE_ORT_INCLUDE_DIR="$runtime_directory/Headers" \
    -DPITCHEE_ORT_LIBRARY="$framework_directory/onnxruntime.framework/onnxruntime"
cmake --build "$test_directory/native" --parallel 4

xcrun swiftc -parse-as-library -O \
    -I "$project_directory/Dependencies/PitcheeCore/platform/ios" \
    -L "$test_directory/native" -l pitchee_core \
    -F "$framework_directory" -framework onnxruntime \
    -framework CoreML -framework Accelerate -framework CoreGraphics \
    -Xlinker -lc++ \
    "$project_directory"/PitcheeApp/Interop/Core/*.swift \
    "$project_directory/PitcheeApp/LivePitchAudioCapture.swift" \
    "$project_directory/Tests/LivePitchTests.swift" \
    -o "$test_directory/live-f0-tests"

"$test_directory/live-f0-tests" "$project_directory/Dependencies/PitcheeCore/models"
