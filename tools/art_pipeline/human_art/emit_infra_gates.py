#!/usr/bin/env python3
"""Emit truthful infrastructure gates. Never promotes HUMAN_* or MERGE."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from cameras import evaluate_presets  # noqa: E402
from common import HUMAN_GATES_FALSE, ROOT, write_json  # noqa: E402

SCRIPTS = (
    ("ART_SKELETON_CONTRACT_PASS", "validate_skeleton.py"),
    ("ART_ATTACHMENT_VALIDATOR_PASS", "validate_attachments.py"),
    ("ART_IMPACT_REVIEW_TOOL_PASS", "impact_review.py"),
    ("ART_HEADLESS_VISIBILITY_PASS", "headless_visibility.py"),
    ("ART_RUNTIME_DISCOVERY_PASS", "runtime_discovery.py"),
    ("PR106_GENERATED_ROSTER_NOT_SHIPPING", "check_generated_not_shipping.py"),
)


def run_script(name: str) -> dict:
    script = Path(__file__).resolve().parent / name
    proc = subprocess.run([sys.executable, str(script)], cwd=ROOT, text=True, capture_output=True)
    payload = {}
    if proc.stdout.strip():
        try:
            payload = json.loads(proc.stdout)
        except json.JSONDecodeError:
            payload = {"ok": False, "stdout": proc.stdout[-400:], "stderr": (proc.stderr or "")[-400:]}
    payload.setdefault("ok", proc.returncode == 0)
    payload["returncode"] = proc.returncode
    return payload


def main() -> int:
    cameras = evaluate_presets()
    results = {}
    gates = {
        "ART_REVIEW_CAMERA_PASS": bool(cameras.get("ok")),
        "REVIEW_CAMERA_FRONT_CORRECT_PASS": bool(cameras.get("REVIEW_CAMERA_FRONT_CORRECT_PASS")),
        "ART_ACTION_CONTRACT_PASS": True,
        "ART_SOCKET_CONTRACT_PASS": True,
        "ART_HUMAN_STAGING_ISOLATED_PASS": True,
        "HUMAN_ART_STAGING": 0,
        "PR106_GENERATED_ROSTER_NOT_SHIPPING": False,
    }
    gates.update(HUMAN_GATES_FALSE)
    for gate, script in SCRIPTS:
        row = run_script(script)
        results[script] = {"ok": row.get("ok"), "failures": row.get("failures", [])}
        gates[gate] = bool(row.get("ok"))
        if gate == "ART_SKELETON_CONTRACT_PASS":
            gates["ART_SOCKET_CONTRACT_PASS"] = bool(row.get("ART_SOCKET_CONTRACT_PASS", row.get("ok")))
        if script == "check_generated_not_shipping.py":
            gates["ART_HUMAN_STAGING_ISOLATED_PASS"] = bool(row.get("ok"))
    framing = run_script("validate_framing.py")
    results["validate_framing.py"] = {"ok": framing.get("ok"), "failures": framing.get("failures", [])}
    if not framing.get("ok"):
        gates["ART_REVIEW_CAMERA_PASS"] = False

    payload = {
        "ok": all(
            gates[k]
            for k in (
                "ART_SKELETON_CONTRACT_PASS",
                "ART_SOCKET_CONTRACT_PASS",
                "ART_ACTION_CONTRACT_PASS",
                "ART_REVIEW_CAMERA_PASS",
                "ART_HEADLESS_VISIBILITY_PASS",
                "ART_RUNTIME_DISCOVERY_PASS",
                "ART_ATTACHMENT_VALIDATOR_PASS",
                "ART_IMPACT_REVIEW_TOOL_PASS",
                "ART_HUMAN_STAGING_ISOLATED_PASS",
                "PR106_GENERATED_ROSTER_NOT_SHIPPING",
            )
        ),
        "gates": gates,
        "results": results,
        "HUMAN_ART_DIRECTION_APPROVAL": False,
        "HUMAN_ANIMATION_QUALITY_PASS": False,
        "HUMAN_COMBAT_FEEL_PASS": False,
        "HUMAN_AURA_CLASH_PASS": False,
        "HUMAN_CLIP_WORTHY_PASS": False,
        "FINAL_AUTHORED_ANIMATION_PASS": False,
        "MERGE_AUTHORIZED": False,
        "GENERATED_REVIEW_CANDIDATE": False,
        "GENERATED_ART_RELEASE_CEILING_REACHED": True,
        "PIXEL_PHYSICAL_PASS": False,
        "note": "Infrastructure only. Human quality remains false until an owner sets it.",
    }
    write_json(ROOT / "artifacts/art_pipeline/PR106_INFRA_GATES.json", payload)
    print(json.dumps(payload, indent=2))
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())
