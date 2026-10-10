#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "=== Testing Voice Training Library & Matching Engine ==="

# Validate the sole generated app resources and, when installed, their Markdown source.
python3 Scripts/build-voice-training-library.py --check
python3 - <<'PYTHON'
import importlib.util
import json
import pathlib
import tempfile
import sys

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("voice_library_builder", "Scripts/build-voice-training-library.py")
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)
with open("Resources/VoiceTrainingLibrary/voice-training-library.json", encoding="utf-8") as source:
    library = json.load(source)
with open("Resources/VoiceTrainingLibrary/voice-rule-matching-matrix.json", encoding="utf-8") as source:
    matrix = json.load(source)
required_keys = {
    "pass_boost", "high_f0_stylized_cap", "high_f0_male_cap",
    "low_f0_natural_cap", "low_f0_stylized_cap", "f0_unavailable",
    "continuous", "score_starter", "score_mid", "score_advanced",
    "score_master", "masculine_specialization", "nonbinary_exploration",
    "guided_practice", "recording_quality", "health_safety", "acoustic_metrics",
}
assert set(matrix) == required_keys
# Translating every heading must preserve roles and icons, including non-Latin copy.
for headings in [
    ["Understanding", "Before practice", "Methods", "References"],
    ["Comprendre", "Observer", "Pratiquer", "Références"],
    ["الفهم", "الملاحظة", "التدريب", "المراجع"],
]:
    markdown = "# Test article\n" + "\n".join("## " + heading + "\nBody" for heading in headings)
    with tempfile.TemporaryDirectory() as directory:
        path = pathlib.Path(directory) / "TEST-01-localized.md"
        path.write_text(markdown, encoding="utf-8")
        article = builder.parse_markdown(str(path))
    assert [section["heading"] for section in article["sections"]] == headings
    assert tuple(section["icon"] for section in article["sections"]) == builder.SECTION_ICONS
print(f"✓ Validated {len(library['articles'])} articles, {len(matrix)} rules and language-independent section roles")
PYTHON

# 2. Compile and run Swift test for VoiceLibraryMatcher and Section Icons
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
project_directory="$REPO_ROOT"
test_directory="$TMP_DIR"
. "$REPO_ROOT/Scripts/core-scoring-test-support.sh"

xcrun swiftc -parse-as-library -swift-version 5 \
    -default-isolation MainActor -strict-concurrency=complete -warnings-as-errors \
    -target "$(uname -m)-apple-macosx14.0" \
    -I "$core_scoring_module_directory" "$core_scoring_object" -lc++ \
    PitcheeApp/Interop/Core/AnalysisResult.swift \
    PitcheeApp/Analysis/VoiceScoring.swift \
    PitcheeApp/Analysis/RecordingStatistics.swift \
    PitcheeApp/Practice/PracticeData.swift \
    PitcheeApp/Practice/VoiceTrainingLibrary.swift \
    Tests/Practice/VoiceTrainingLibraryTests.swift \
    -o "$TMP_DIR/matcher-test-bin"

"$TMP_DIR/matcher-test-bin" "$REPO_ROOT/Resources/VoiceTrainingLibrary"

echo "=== Voice Training Library verification 100% SUCCESS ==="
