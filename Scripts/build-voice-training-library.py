#!/usr/bin/env python3
"""
build-voice-training-library.py
Builds the machine-readable voice-training-library.json and voice-rule-matching-matrix.json
from Documents/Articles / Docs/Voice-Training-Library markdown files for Pitchee iOS App integration.
"""

import os
import re
import json
import glob
from datetime import datetime, timezone

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if os.path.exists(os.path.join(SCRIPT_DIR, "Module-01-Engine-Rules")):
    # Running directly inside Articles repository root
    REPO_ROOT = SCRIPT_DIR
    LOCAL_DOCS_DIR = SCRIPT_DIR
    STANDALONE_ARTICLES_DIR = SCRIPT_DIR
    LIBRARY_DOCS_DIR = SCRIPT_DIR
    RESOURCES_DIR = SCRIPT_DIR
else:
    REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    LOCAL_DOCS_DIR = os.path.join(REPO_ROOT, "Docs", "Voice-Training-Library")
    # Only use the requested source checkout; do not silently read or overwrite a sibling repository.
    LIBRARY_DOCS_DIR = os.path.abspath(os.environ.get("ARTICLES_DIR") or LOCAL_DOCS_DIR)

    RESOURCES_DIR = os.path.join(REPO_ROOT, "Resources", "VoiceTrainingLibrary")
    os.makedirs(RESOURCES_DIR, exist_ok=True)

SECTION_ICON_MAP = {
    "一、理解这项主题": "gearshape.2.fill",
    "二、练习前的观察": "stethoscope",
    "三、可尝试的方法": "figure.run",
    "四、依据与延伸阅读": "books.vertical.fill"
}

def icon_for_heading(heading):
    if heading in SECTION_ICON_MAP:
        return SECTION_ICON_MAP[heading]
    if "机制" in heading or "原理" in heading:
        return "gearshape.2.fill"
    if "自查" in heading or "排查" in heading or "症状" in heading:
        return "stethoscope"
    if "训练" in heading or "动作" in heading or "实操" in heading or "指南" in heading:
        return "figure.run"
    if "文献" in heading or "参考" in heading or "循证" in heading:
        return "books.vertical.fill"
    return "doc.text.fill"

def parse_markdown(filepath):
    rel_path = os.path.relpath(filepath, LIBRARY_DOCS_DIR)
    folder = os.path.dirname(rel_path)
    filename = os.path.basename(rel_path)
    
    # Extract ID ending with two digits before Chinese/descriptive slug
    id_match = re.match(r"^([A-Z0-9\-]+?-\d{2})-(.*)\.md$", filename)
    if id_match:
        full_id = id_match.group(1)
        slug = id_match.group(2)
    else:
        full_id = filename.replace(".md", "")
        slug = full_id

    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    lines = content.splitlines()
    title = ""
    for line in lines:
        if line.startswith("# "):
            title = line[2:].strip()
            break

    # Extract all metadata bullet points in header
    meta = {}
    for line in lines[:25]:
        m = re.match(r"^\s*[-*]\s*\*\*([^*]+)\*\*[:：]\s*(.*)$", line.strip())
        if m:
            meta[m.group(1).strip()] = m.group(2).strip()

    summary = (
        meta.get("适用场景") or 
        meta.get("推荐场景") or 
        meta.get("适用周期") or 
        meta.get("核心场景") or 
        title
    )

    user_persona = (
        meta.get("用户痛点") or 
        meta.get("适用人群") or 
        meta.get("用户困惑") or 
        meta.get("阶段痛点") or 
        meta.get("用户画像") or 
        meta.get("生理现状") or 
        meta.get("常见症状") or 
        meta.get("心理反应") or 
        meta.get("心理现状") or 
        meta.get("能力瓶颈") or 
        meta.get("心理根源") or 
        meta.get("阶段特征") or 
        meta.get("阶段困惑") or 
        ""
    )

    core_goal = (
        meta.get("核心目标") or 
        meta.get("阶段目标") or 
        meta.get("科学真相") or 
        meta.get("核心认知") or 
        ""
    )

    # Determine tags and matching conditions
    matched_rules = []
    target_preferences = ["feminine", "masculine", "undecided"]
    min_score = 0
    max_score = 100

    if "RULE-PASS-BOOST" in filename:
        matched_rules = ["pass_boost"]
        target_preferences = ["feminine"]
        min_score = 80
        max_score = 100
    elif "RULE-HIGH-F0-STYLIZED" in filename:
        matched_rules = ["high_f0_stylized_cap"]
        target_preferences = ["feminine"]
        min_score = 0
        max_score = 30
    elif "RULE-HIGH-F0-MALE" in filename:
        matched_rules = ["high_f0_male_cap"]
        target_preferences = ["feminine"]
        min_score = 30
        max_score = 59
    elif "RULE-LOW-F0-NATURAL" in filename:
        matched_rules = ["low_f0_natural_cap"]
        target_preferences = ["feminine"]
        min_score = 40
        max_score = 59
    elif "RULE-LOW-F0-STYLIZED" in filename:
        matched_rules = ["low_f0_stylized_cap"]
        target_preferences = ["feminine"]
        min_score = 0
        max_score = 20
    elif "RULE-F0-UNAVAILABLE" in filename:
        matched_rules = ["f0_unavailable"]
        target_preferences = ["feminine", "masculine", "undecided"]
    elif "RULE-CONTINUOUS" in filename:
        matched_rules = ["continuous"]
        target_preferences = ["feminine", "masculine", "undecided"]
    elif "SCORE-STARTER" in filename:
        min_score = 0
        max_score = 49
        target_preferences = ["feminine"]
        matched_rules = ["continuous"]
    elif "SCORE-MID" in filename:
        min_score = 50
        max_score = 74
        target_preferences = ["feminine"]
        matched_rules = ["continuous"]
    elif "SCORE-ADVANCED" in filename:
        min_score = 75
        max_score = 89
        target_preferences = ["feminine"]
        matched_rules = ["continuous"]
    elif "SCORE-MASTER" in filename:
        min_score = 90
        max_score = 100
        target_preferences = ["feminine"]
        matched_rules = ["continuous"]
    elif "MASCULINE" in filename:
        target_preferences = ["masculine"]
        matched_rules = ["continuous", "masculine"]
    elif "NONBINARY" in filename:
        target_preferences = ["undecided"]
        matched_rules = ["continuous", "nonbinary"]
    elif "PRACTICE-AB" in filename:
        target_preferences = ["feminine", "masculine", "undecided"]
        matched_rules = ["guided_practice"]
    elif "QUALITY" in filename or "METRIC-DURATION" in filename:
        target_preferences = ["feminine", "masculine", "undecided"]
        matched_rules = ["quality"]
    elif "HEALTH" in filename:
        target_preferences = ["feminine", "masculine", "undecided"]
        matched_rules = ["health_clinical"]
    elif "METRIC" in filename:
        target_preferences = ["feminine", "masculine", "undecided"]
        matched_rules = ["acoustic_dimensions"]

    # Extract sections
    sections = []
    current_sec = None
    for line in lines:
        if line.startswith("## "):
            if current_sec:
                sections.append(current_sec)
            heading_text = line[3:].strip()
            current_sec = {"heading": heading_text, "content": []}
        elif current_sec:
            current_sec["content"].append(line)
    if current_sec:
        sections.append(current_sec)

    clean_sections = []
    for s in sections:
        clean_sections.append({
            "heading": s["heading"],
            "icon": icon_for_heading(s["heading"]),
            "body": "\n".join(s["content"]).strip()
        })

    return {
        "id": full_id,
        "title": title,
        "category": folder,
        "filename": filename,
        "summary": summary,
        "userPersona": user_persona,
        "coreGoal": core_goal,
        "matchedRules": matched_rules,
        "targetPreferences": target_preferences,
        "scoreRange": {"min": min_score, "max": max_score},
        "sections": clean_sections,
        "rawContent": content
    }

def main():
    md_files = sorted([f for f in glob.glob(os.path.join(LIBRARY_DOCS_DIR, "**", "*.md"), recursive=True) if not f.endswith("README.md")])
    if len(md_files) != 49:
        raise ValueError(f"Expected 49 articles in {LIBRARY_DOCS_DIR}, found {len(md_files)}")
    articles = []
    for f in md_files:
        articles.append(parse_markdown(f))

    print(f"Parsed {len(articles)} articles from {LIBRARY_DOCS_DIR}.")

    output_payload = {
        "schemaVersion": "1.0.0",
        "generatedAt": datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z"),
        "description": "Pitchee iOS App Embedded Voice Training Text Resource Library",
        "totalArticles": len(articles),
        "articles": articles
    }

    # Write structured library to Resources/VoiceTrainingLibrary
    lib_path = os.path.join(RESOURCES_DIR, "voice-training-library.json")
    with open(lib_path, "w", encoding="utf-8") as f:
        json.dump(output_payload, f, ensure_ascii=False, indent=2)
    print(f"Wrote structured library to {lib_path}")

    # Build rule matching matrix
    rule_matrix = {
        "pass_boost": [a["id"] for a in articles if "pass_boost" in a["matchedRules"]],
        "high_f0_stylized_cap": [a["id"] for a in articles if "high_f0_stylized_cap" in a["matchedRules"]],
        "high_f0_male_cap": [a["id"] for a in articles if "high_f0_male_cap" in a["matchedRules"]],
        "low_f0_natural_cap": [a["id"] for a in articles if "low_f0_natural_cap" in a["matchedRules"]],
        "low_f0_stylized_cap": [a["id"] for a in articles if "low_f0_stylized_cap" in a["matchedRules"]],
        "f0_unavailable": [a["id"] for a in articles if "f0_unavailable" in a["matchedRules"]],
        "continuous": [a["id"] for a in articles if "continuous" in a["matchedRules"]],
        "score_starter": [a["id"] for a in articles if a["id"].startswith("SCORE-STARTER")],
        "score_mid": [a["id"] for a in articles if a["id"].startswith("SCORE-MID")],
        "score_advanced": [a["id"] for a in articles if a["id"].startswith("SCORE-ADVANCED")],
        "score_master": [a["id"] for a in articles if a["id"].startswith("SCORE-MASTER")],
        "masculine_specialization": [a["id"] for a in articles if a["targetPreferences"] == ["masculine"]],
        "nonbinary_exploration": [a["id"] for a in articles if a["targetPreferences"] == ["undecided"]],
        "guided_practice": [a["id"] for a in articles if a["id"].startswith("PRACTICE-AB")],
        "recording_quality": [a["id"] for a in articles if a["id"].startswith("QUALITY") or a["id"].startswith("METRIC-DURATION")],
        "health_safety": [a["id"] for a in articles if a["id"].startswith("HEALTH")],
        "acoustic_metrics": [a["id"] for a in articles if a["id"].startswith("METRIC")]
    }

    matrix_path = os.path.join(RESOURCES_DIR, "voice-rule-matching-matrix.json")
    with open(matrix_path, "w", encoding="utf-8") as f:
        json.dump(rule_matrix, f, ensure_ascii=False, indent=2)
    print(f"Wrote matching matrix to {matrix_path}")

    # Mirror only into the source actually used for this build.
    target_mirror_dirs = []
    if os.path.abspath(LIBRARY_DOCS_DIR) != os.path.abspath(RESOURCES_DIR):
        target_mirror_dirs.append(LIBRARY_DOCS_DIR)

    for mdir in target_mirror_dirs:
        if os.path.exists(mdir):
            m_lib_path = os.path.join(mdir, "voice-training-library.json")
            with open(m_lib_path, "w", encoding="utf-8") as f:
                json.dump(output_payload, f, ensure_ascii=False, indent=2)
            m_mat_path = os.path.join(mdir, "voice-rule-matching-matrix.json")
            with open(m_mat_path, "w", encoding="utf-8") as f:
                json.dump(rule_matrix, f, ensure_ascii=False, indent=2)
            print(f"Wrote mirror JSON copies to {mdir}")

if __name__ == "__main__":
    main()
