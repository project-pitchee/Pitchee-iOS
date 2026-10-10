#!/bin/sh
# Source after setting project_directory and test_directory. The two exported
# paths are explicit swiftc arguments so directories containing spaces work.
core_scoring_module_directory="$project_directory/Dependencies/PitcheeCore/platform/ios"
core_scoring_object="$test_directory/pitchee-scoring.o"
xcrun clang++ -std=c++17 -O2 -mmacosx-version-min=14.0 \
    -I "$project_directory/Dependencies/PitcheeCore/src" \
    -I "$project_directory/Dependencies/PitcheeCore/include" \
    -c "$project_directory/Dependencies/PitcheeCore/src/scoring.cpp" \
    -o "$core_scoring_object"
