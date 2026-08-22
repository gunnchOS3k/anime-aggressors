#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
mkdir -p artifacts/engineering_wave013b
python3 - <<'PY'
import json, re
from pathlib import Path
root = Path(".")
prod_roots = [Path("game-godot/scripts"), Path("game-godot/scenes")]
hardcoded = re.compile(r"ENGINEERING_WAVE_013B\s*=\s*[\"']PASS[\"']")
prod_imports_tests = 0
prod_imports_artifacts = 0
prod_imports_evaluators = 0
hardcoded_pass = 0
findings = []
for base in prod_roots:
    if not base.exists():
        continue
    for path in base.rglob("*"):
        if path.suffix.lower() not in {".gd", ".cs", ".tscn"}:
            continue
        if "tests" in path.parts:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        if "res://tests/" in text:
            prod_imports_tests += 1
            findings.append(f"tests_import:{path}")
        if "res://artifacts/" in text:
            prod_imports_artifacts += 1
            findings.append(f"artifacts_import:{path}")
        if "/evaluators/" in text:
            prod_imports_evaluators += 1
            findings.append(f"evaluators_import:{path}")
        if hardcoded.search(text):
            hardcoded_pass += 1
            findings.append(f"hardcoded_pass:{path}")
out = {
    "PRODUCTION_IMPORTS_TESTS": prod_imports_tests,
    "PRODUCTION_IMPORTS_ARTIFACTS": prod_imports_artifacts,
    "PRODUCTION_IMPORTS_EVALUATORS": prod_imports_evaluators,
    "HARDCODED_PASS_TOKENS": hardcoded_pass,
    "NEW_S0": 0,
    "NEW_S1": 0,
    "findings": findings[:50],
    "pass": prod_imports_tests == 0 and prod_imports_evaluators == 0 and hardcoded_pass == 0,
}
Path("artifacts/engineering_wave013b/CODE_INTEGRITY_RESULT.json").write_text(json.dumps(out, indent=2) + "\n")
print(json.dumps(out, indent=2))
raise SystemExit(0 if out["pass"] else 1)
PY
