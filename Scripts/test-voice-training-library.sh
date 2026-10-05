#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "=== Testing Voice Training Library & Matching Engine ==="

# 1. Run Python validation on Markdown articles and JSON output
python3 -c '
import json, os, glob

expected_headings = [
    "## 一、理解这项主题",
    "## 二、练习前的观察",
    "## 三、可尝试的方法",
    "## 四、依据与延伸阅读"
]

expected_icons = [
    "gearshape.2.fill",
    "stethoscope",
    "figure.run",
    "books.vertical.fill"
]

# Validate the source chosen by the builder, not an unrelated sibling checkout.
docs_dir = os.environ.get("ARTICLES_DIR") or "Docs/Voice-Training-Library"
md_files = [f for f in glob.glob(os.path.join(docs_dir, "**", "*.md"), recursive=True) if not f.endswith("README.md")]
assert len(md_files) == 49, f"Expected 49 articles in {docs_dir}, found {len(md_files)}"
for f in md_files:
    with open(f, "r", encoding="utf-8") as fp:
        text = fp.read()
        assert not ("---\n\n\n---" in text or "---\n\n---" in text), f"Double divider in {f}"
        h2s = [l.strip() for l in text.splitlines() if l.startswith("## ")]
        assert h2s == expected_headings, f"Article {f} has non-standard headings: {h2s}"
print(f"✓ Validated all {len(md_files)} articles in {docs_dir} with standard 4-section architecture & clean dividers")

# Check compiled JSON in Resources/VoiceTrainingLibrary
json_path = "Resources/VoiceTrainingLibrary/voice-training-library.json"
assert os.path.exists(json_path), "JSON library missing"
with open(json_path, "r", encoding="utf-8") as fp:
    data = json.load(fp)

assert data["schemaVersion"] == "1.0.0"
assert len(data["articles"]) == 49
for art in data["articles"]:
    aid = art.get("id")
    assert aid, f"Missing id: {art}"
    assert art["title"], f"Missing title in {aid}"
    assert art["summary"], f"Missing summary in {aid}"
    assert art["userPersona"], f"Missing userPersona in {aid}"
    assert art["coreGoal"], f"Missing coreGoal in {aid}"
    assert len(art["sections"]) == 4, f"Expected 4 sections in {aid}, got {len(art['sections'])}"
    icons = [s.get("icon") for s in art["sections"]]
    assert icons == expected_icons, f"Unexpected icons in {aid}: {icons}"
    for s_idx, sec in enumerate(art["sections"]):
        assert len(sec.get("body", "").strip()) >= 80, f"Section {s_idx+1} in {aid} too short: {sec.get('body')}"

print(f"✓ Validated 49 articles in JSON with complete metadata, substantial content in all 4 sections, and 100% SF Symbol mapping")

matrix_path = "Resources/VoiceTrainingLibrary/voice-rule-matching-matrix.json"
assert os.path.exists(matrix_path), "Matrix JSON missing"
with open(matrix_path, "r", encoding="utf-8") as f:
    matrix = json.load(f)

required_keys = [
    "pass_boost", "high_f0_stylized_cap", "high_f0_male_cap",
    "low_f0_natural_cap", "low_f0_stylized_cap", "f0_unavailable",
    "continuous", "score_starter", "score_mid", "score_advanced",
    "score_master", "masculine_specialization", "nonbinary_exploration",
    "guided_practice", "recording_quality", "health_safety", "acoustic_metrics"
]
for k in required_keys:
    assert k in matrix and len(matrix[k]) > 0, f"Missing or empty matrix category: {k}"
print(f"✓ Validated rule matching matrix with all {len(required_keys)} categories")
'

# 2. Compile and run Swift test for VoiceLibraryMatcher and Section Icons
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

xcrun swiftc -parse-as-library -swift-version 5 \
    -default-isolation MainActor -strict-concurrency=complete -warnings-as-errors \
    -target "$(uname -m)-apple-macosx14.0" \
    PitcheeApp/Interop/Core/AnalysisResult.swift \
    PitcheeApp/Analysis/VoiceScoring.swift \
    PitcheeApp/Analysis/RecordingStatistics.swift \
    PitcheeApp/Practice/PracticeData.swift \
    PitcheeApp/Practice/VoiceTrainingLibrary.swift \
    Tests/Practice/VoiceTrainingLibraryTests.swift \
    -o "$TMP_DIR/matcher-test-bin"

"$TMP_DIR/matcher-test-bin"

echo "=== Voice Training Library verification 100% SUCCESS ==="
