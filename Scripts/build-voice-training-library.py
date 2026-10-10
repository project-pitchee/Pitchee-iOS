#!/usr/bin/env python3
"""
build-voice-training-library.py
Builds the machine-readable voice-training-library.json and voice-rule-matching-matrix.json
from the explicitly selected Markdown source into the sole app resource directory.
Use --check to validate resources and detect source drift without writing files.
"""

import os
import re
import json
import glob
import argparse
import hashlib

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

# The library schema defines four ordered roles: understand, observe, practice,
# references. Display headings are translated copy, never classification keys.
SECTION_ICONS = (
    "gearshape.2.fill",
    "stethoscope",
    "figure.run",
    "books.vertical.fill",
)

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

    if len(sections) != len(SECTION_ICONS):
        raise ValueError(f"Expected four ordered sections in {filepath}, found {len(sections)}")
    clean_sections = []
    for index, s in enumerate(sections):
        clean_sections.append({
            "heading": s["heading"],
            "icon": SECTION_ICONS[index],
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
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Validate generated resources without rewriting any checkout")
    args = parser.parse_args()
    validate_resources_only = args.check and not os.environ.get("ARTICLES_DIR") and not os.path.isdir(LIBRARY_DOCS_DIR)
    if validate_resources_only:
        validate_resources()
        print("Validated bundled resources; Markdown source checkout is not installed.")
        return
    md_files = sorted([f for f in glob.glob(os.path.join(LIBRARY_DOCS_DIR, "**", "*.md"), recursive=True) if not f.endswith("README.md")])
    if len(md_files) != 49:
        raise ValueError(f"Expected 49 articles in {LIBRARY_DOCS_DIR}, found {len(md_files)}")
    articles = []
    for f in md_files:
        articles.append(parse_markdown(f))

    print(f"Parsed {len(articles)} articles from {LIBRARY_DOCS_DIR}.")

    digest = hashlib.sha256()
    for path in md_files:
        digest.update(os.path.relpath(path, LIBRARY_DOCS_DIR).encode("utf-8"))
        digest.update(b"\0")
        with open(path, "rb") as source:
            digest.update(source.read())
        digest.update(b"\0")
    output_payload = {
        "schemaVersion": "1.0.0",
        "sourceSHA256": digest.hexdigest(),
        "description": "Pitchee iOS App Embedded Voice Training Text Resource Library",
        "totalArticles": len(articles),
        "articles": articles
    }

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

    outputs = {
        "voice-training-library.json": output_payload,
        "voice-rule-matching-matrix.json": rule_matrix,
    }
    if args.check:
        for name, payload in outputs.items():
            with open(os.path.join(RESOURCES_DIR, name), encoding="utf-8") as source:
                actual = json.load(source)
            if actual != payload:
                raise ValueError(f"{name} differs from Markdown source; run Scripts/build-voice-training-library.py")
        validate_resources()
        print("Bundled JSON matches the Markdown source and generator.")
    else:
        os.makedirs(RESOURCES_DIR, exist_ok=True)
        for name, payload in outputs.items():
            path = os.path.join(RESOURCES_DIR, name)
            with open(path, "w", encoding="utf-8") as output:
                json.dump(payload, output, ensure_ascii=False, indent=2)
                output.write("\n")
            print(f"Wrote {path}")
        validate_resources()


def validate_resources():
    with open(os.path.join(RESOURCES_DIR, "voice-training-library.json"), encoding="utf-8") as source:
        library = json.load(source)
    with open(os.path.join(RESOURCES_DIR, "voice-rule-matching-matrix.json"), encoding="utf-8") as source:
        matrix = json.load(source)
    articles = library["articles"]
    if library["schemaVersion"] != "1.0.0" or library["totalArticles"] != len(articles) or len(articles) != 49:
        raise ValueError("Invalid library schema or article count")
    ids = {article["id"] for article in articles}
    if len(ids) != len(articles):
        raise ValueError("Duplicate article IDs")
    for article in articles:
        for field in ["id", "title", "summary", "userPersona", "coreGoal"]:
            if not article[field]:
                raise ValueError(f"Missing {field} in {article['id']}")
        if tuple(section.get("icon") for section in article["sections"]) != SECTION_ICONS:
            raise ValueError(f"Invalid section roles in {article['id']}")
        if any(len(section["body"].strip()) < 80 for section in article["sections"]):
            raise ValueError(f"Incomplete section body in {article['id']}")
    if not matrix or any(not values or not set(values) <= ids for values in matrix.values()):
        raise ValueError("Empty rules or unknown article IDs in matching matrix")


if __name__ == "__main__":
    main()
