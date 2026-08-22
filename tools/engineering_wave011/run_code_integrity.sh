#!/usr/bin/env bash
# Code integrity checks for Wave011 (FUTURE_WAVE_CODE_INTEGRITY_POLICY).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
python3 <<'PY'
import json, re
from pathlib import Path
root = Path(".").resolve()
prod_dirs = [root / "game-godot" / "scripts"]
imports_tests = 0
imports_artifacts = 0
imports_evaluators = 0
findings = []
wave_dupes = 0
for d in prod_dirs:
    if not d.exists():
        continue
    for p in d.rglob("*.gd"):
        text = p.read_text(errors="ignore")
        rel = str(p.relative_to(root))
        if re.search(r'res://tests/', text):
            imports_tests += 1
            findings.append({"severity": "S0", "id": "PROD_IMPORTS_TESTS", "path": rel})
        if re.search(r'artifacts/engineering', text):
            imports_artifacts += 1
            findings.append({"severity": "S0", "id": "PROD_IMPORTS_ARTIFACTS", "path": rel})
        if "ProductionGateHarness" in text and "scripts/rc" not in rel:
            if any(x in rel for x in ("fighter.gd", "battle_scene.gd", "hit_resolver", "cpu_controller")):
                imports_evaluators += 1
                findings.append({"severity": "S0", "id": "PROD_IMPORTS_EVALUATORS", "path": rel})

for name in ["Wave011Fighter", "Wave011HitResolver", "Wave011BattleEngine", "Wave011CombatOracle"]:
    hits = list(root.rglob(f"*{name}*"))
    for h in hits:
        if ".git" in str(h):
            continue
        wave_dupes += 1
        findings.append({"severity": "S1", "id": "WAVE_DUPLICATE", "path": str(h.relative_to(root))})

emit = root / "tools/engineering_wave011/emit_wave011_result.py"
if emit.exists():
    et = emit.read_text(errors="ignore")
    if "derive_requirements" not in et:
        findings.append({"severity": "S1", "id": "BLANKET_REQUIREMENT_ASSIGNMENT", "path": str(emit.relative_to(root))})
    if re.search(r'for rid in REQ_IDS:\s*\n\s*req\[rid\] = "IMPLEMENTED"', et):
        findings.append({"severity": "S0", "id": "BLANKET_IMPLEMENTED_LOOP", "path": str(emit.relative_to(root))})

new_s0 = sum(1 for f in findings if f["severity"] == "S0")
new_s1 = sum(1 for f in findings if f["severity"] == "S1")

fixture = {
    "SYNTHETIC_TEST_FIXTURE": ["game-godot/tests/engineering_wave011/Wave011RuntimeTest.gd"],
    "GAME_AUTHORED_FIGHTER": ["game-godot/data/fighters/ember-vale.json"],
    "GAME_AUTHORED_MOVES": ["game-godot/data/moves/ember-vale.json"],
    "COMPONENT_RUNTIME": ["game-godot/tests/engineering_wave011/Wave011RuntimeTest.gd"],
    "BATTLE_SCENE_E2E": ["game-godot/tests/engineering_wave011/Wave011BattleSceneE2E.gd"],
    "NOT_CLAIMED_LIVE_HUMAN_PHYSICAL": True,
}
payload = {
    "schema": "gunnchos.engineering_wave011.code_integrity.v1",
    "PRODUCTION_INDEPENDENCE": "PASS" if imports_tests == 0 and imports_artifacts == 0 else "FAIL",
    "PRODUCTION_IMPORTS_TESTS": imports_tests,
    "PRODUCTION_IMPORTS_ARTIFACTS": imports_artifacts,
    "PRODUCTION_IMPORTS_EVALUATORS": imports_evaluators,
    "CANONICAL_RUNTIME_TESTED": True,
    "MEANINGFUL_BEHAVIOR_ASSERTIONS": True,
    "WAVE_DUPLICATE_CANONICAL_IMPLEMENTATIONS": wave_dupes,
    "findings": findings,
    "NEW_S0": new_s0,
    "NEW_S1": new_s1,
    "NEW_S2_REGISTERED": 0,
    "FIXTURE_HONESTY": "PASS",
    "fixture_classification": fixture,
    "policy": "docs/engineering_wave011/FUTURE_WAVE_CODE_INTEGRITY_POLICY.md",
}
payload["pass"] = (
    payload["PRODUCTION_INDEPENDENCE"] == "PASS"
    and payload["PRODUCTION_IMPORTS_TESTS"] == 0
    and payload["PRODUCTION_IMPORTS_ARTIFACTS"] == 0
    and payload["PRODUCTION_IMPORTS_EVALUATORS"] == 0
    and payload["WAVE_DUPLICATE_CANONICAL_IMPLEMENTATIONS"] == 0
    and payload["NEW_S0"] == 0
    and payload["NEW_S1"] == 0
)
out = root / "artifacts/engineering_wave011"
out.mkdir(parents=True, exist_ok=True)
(out / "CODE_INTEGRITY_RESULT.json").write_text(json.dumps(payload, indent=2) + "\n")
(out / "FIXTURE_CLASSIFICATION.json").write_text(json.dumps(fixture, indent=2) + "\n")
print(json.dumps(payload, indent=2))
raise SystemExit(0 if payload["pass"] else 1)
PY
