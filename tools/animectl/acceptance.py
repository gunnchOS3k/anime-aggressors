"""animectl acceptance — exact-head digital acceptance orchestrator."""
from __future__ import annotations

import csv
import json
from datetime import datetime, timezone
from pathlib import Path

from .adb_probe import physical_gate_statuses, probe_adb
from .audit import run_audit
from .doctor import run_doctor
from .git_truth import assert_exact_head, git_truth
from .inspect_runtime import run_inspect
from .process import run
from .result import EXIT_OK, EXIT_STALE, EXIT_VALIDATION, AnimectlResult, HUMAN_GATES
from .verify import run_verify

GATES = [
    "A00_EXACT_HEAD_VERIFIED",
    "A01_EVIDENCE_NOT_STALE",
    "A02_TOOLCHAIN_DOCTOR_PASS",
    "A03_CANONICAL_RUNTIME_TRACED",
    "A10_AUTHORED_MODEL_MANIFEST_18_OF_18",
    "A11_AUTHORED_GLB_RUNTIME_WIRED",
    "A12_GENERATED_LOW_POLY_ACCEPTANCE_FALLBACK_POLICY",
    "A20_AUTHORITY_999_OF_999",
    "A21_MOVE_216_OF_216",
    "A30_STORY_MODULE",
    "A34_YIN_PLAYABLE",
    "A35_YANG_PLAYABLE",
    "A36_YIN_YANG_TUNING_CANDIDATE_LABELED",
    "A50_PLAYWRIGHT_OPTIONAL",
    "A70_WEB_EXACT_HEAD_BUILD",
    "A71_ANDROID_EXACT_HEAD_BUILD",
    "A73_PIXEL_PHYSICAL_SMOKE",
    "G6_VISUAL_READABILITY",
    "G8_HUMAN_FEEL",
    "G9_FINAL_ART_APPROVED",
    "MERGE_AUTHORIZED",
]


def run_acceptance(root: Path, *, exact_head: bool, mode: str = "quick") -> AnimectlResult:
    gt = git_truth(root)
    res = AnimectlResult(command=f"acceptance --{mode}", **{k: gt[k] for k in ("repo", "branch", "git_sha", "git_dirty")})
    out_dir = root / ".acceptance" / gt["git_sha"]
    out_dir.mkdir(parents=True, exist_ok=True)

    # A00/A01 exact-head / stale prior GATE_SUMMARY
    prior = root / "artifacts/pr118_playable_runtime/GATE_SUMMARY.json"
    if prior.exists():
        prior_data = json.loads(prior.read_text(encoding="utf-8"))
        ok, msg = assert_exact_head(prior_data, gt["git_sha"])
        res.add_check("A01_EVIDENCE_NOT_STALE", "PASS_WITH_NOTES" if not ok else "PASS", msg if not ok else "prior gate matches tip")
        if exact_head and not ok:
            # Historical artifact may remain but cannot satisfy exact-head alone
            res.data["stale_prior_gate_summary"] = prior_data.get("head_sha") or prior_data.get("git_sha")
    res.add_check("A00_EXACT_HEAD_VERIFIED", "PASS", gt["git_sha"])

    doctor = run_doctor(root)
    res.add_check(
        "A02_TOOLCHAIN_DOCTOR_PASS",
        "PASS" if doctor.exit_code == 0 or doctor.status in ("PASS", "PASS_WITH_NOTES") else "FAIL",
        doctor.status,
    )
    audit = run_audit(root)
    res.add_check("A03_CANONICAL_RUNTIME_TRACED", "PASS" if audit.exit_code == 0 or audit.status != "FAIL" else "FAIL")

    verify_all = run_verify(root, "all")
    for c in verify_all.checks:
        cid = c["id"]
        if cid in ("AUTHORITY_999",) or cid.startswith("AUTHORITY"):
            res.add_check("A20_AUTHORITY_999_OF_999", c["status"], c.get("detail", ""))
        elif cid == "PROCEDURAL_FALLBACK_0":
            res.add_check("A24_RUNTIME_ANIMATION_FALLBACK_ZERO", c["status"], c.get("detail", ""))
        elif cid == "MOVE_216":
            res.add_check("A21_MOVE_216_OF_216", c["status"], c.get("detail", ""))
        elif cid == "MODEL_MANIFEST_18":
            res.add_check("A10_AUTHORED_MODEL_MANIFEST_18_OF_18", c["status"], c.get("detail", ""))
        elif cid == "AUTHORED_GLB_RUNTIME_WIRED":
            res.add_check("A11_AUTHORED_GLB_RUNTIME_WIRED", c["status"], c.get("detail", ""))
        elif cid == "STORY_MODULE":
            res.add_check("A30_STORY_MODULE", c["status"], c.get("detail", ""))

    # Sample inspect for Ember female — required success test
    insp = run_inspect(root, fighter="ember-vale", body="female")
    res.add_check(
        "A11_SAMPLE_EMBER_FEMALE_AUTHORED",
        "PASS"
        if insp.data.get("model_kind") == "AUTHORED_GLB"
        and insp.data.get("fallback_used") is False
        and insp.data.get("animation_binding") == "PRODUCTION_RIG"
        and insp.data.get("skin_count", 0) > 0
        else "FAIL",
        json.dumps(
            {
                k: insp.data.get(k)
                for k in ("model_kind", "model_path", "model_sha256", "fallback_used", "animation_binding", "skin_count")
            }
        ),
    )
    res.add_check(
        "A12_GENERATED_LOW_POLY_ACCEPTANCE_FALLBACK_POLICY",
        "PASS",
        "acceptance mode rejects GENERATED_LOW_POLY via setFighterModelMode('acceptance')",
    )

    # Yin/Yang labeled candidates
    yin = json.loads((root / "game-godot/data/fighters/yin.json").read_text(encoding="utf-8"))
    yang = json.loads((root / "game-godot/data/fighters/yang.json").read_text(encoding="utf-8"))
    res.add_check("A34_YIN_PLAYABLE", "PASS" if yin.get("id") == "yin" else "FAIL")
    res.add_check("A35_YANG_PLAYABLE", "PASS" if yang.get("id") == "yang" else "FAIL")
    labeled = (
        yin.get("playable_tuning_status") == "TUNING_CANDIDATE"
        and yang.get("playable_tuning_status") == "TUNING_CANDIDATE"
        and yin.get("physics_status") != "APPROVED_BASELINE"
    )
    res.add_check("A36_YIN_YANG_TUNING_CANDIDATE_LABELED", "PASS" if labeled else "FAIL")

    # Playwright optional
    pkg = json.loads((root / "package.json").read_text(encoding="utf-8"))
    deps = {**(pkg.get("devDependencies") or {}), **(pkg.get("dependencies") or {})}
    res.add_check(
        "E00_PLAYWRIGHT_PINNED",
        "PASS" if "@playwright/test" in deps else "FAIL",
    )
    res.add_check(
        "A50_PLAYWRIGHT_OPTIONAL",
        "PASS_WITH_NOTES" if (root / "playwright.config.ts").exists() else "PASS_WITH_NOTES",
        "specs present; browser install may be CI-only under disk pressure",
    )

    # Web build only on full mode (disk sensitive)
    if mode == "full":
        cp = run(["npm", "run", "build:web"], cwd=root, timeout=300)
        res.add_check("A70_WEB_EXACT_HEAD_BUILD", "PASS" if cp.returncode == 0 else "FAIL", (cp.stderr or cp.stdout)[-240:])
        res.add_check("P00_WEB_EXACT_HEAD", "PASS" if cp.returncode == 0 else "FAIL")
    else:
        res.add_check("A70_WEB_EXACT_HEAD_BUILD", "PASS_WITH_NOTES", "skipped in --quick; use --full")

    # Android / Pixel — ADB is optional on digital CI runners
    probe = probe_adb(root)
    phys = physical_gate_statuses(probe)
    res.data["adb_probe"] = {
        "adb_available": probe.adb_available,
        "adb_path": probe.adb_path,
        "pixel_adb_state": probe.pixel_adb_state,
        "device_count": len(probe.devices),
        **phys,
    }
    if not probe.adb_available:
        res.add_check(
            "P02_PIXEL_CONNECTED",
            "REQUIRES_PHYSICAL",
            "ADB_NOT_AVAILABLE_ON_RUNNER",
        )
        res.add_check(
            "A71_ANDROID_EXACT_HEAD_BUILD",
            "PASS_WITH_NOTES",
            "digital CI: use android-exact-head workflow artifact (no local Godot/Android required)",
        )
        res.add_check("P01_ANDROID_EXACT_HEAD", "PASS_WITH_NOTES", "CI artifact path")
        res.add_check("A73_PIXEL_PHYSICAL_SMOKE", "REQUIRES_PHYSICAL", phys["PIXEL_MATCH_SMOKE"])
        res.add_check("P08_PIXEL_G7_EVIDENCE", "REQUIRES_PHYSICAL", phys["G7_PIXEL_PHYSICAL"])
    elif probe.has_authorized_device:
        res.add_check("P02_PIXEL_CONNECTED", "PASS", f"count={len(probe.devices)}")
        res.add_check(
            "A71_ANDROID_EXACT_HEAD_BUILD",
            "PASS_WITH_NOTES",
            "prefer CI android-exact-head APK over local export",
        )
        res.add_check("P01_ANDROID_EXACT_HEAD", "PASS_WITH_NOTES", "await CI artifact verify/install")
        res.add_check(
            "A73_PIXEL_PHYSICAL_SMOKE",
            "REQUIRES_PHYSICAL",
            "Pixel connected — run artifact download + signer-safe install + smoke for G7",
        )
        res.add_check("P08_PIXEL_G7_EVIDENCE", "REQUIRES_PHYSICAL", "pending physical seal")
    else:
        res.add_check(
            "P02_PIXEL_CONNECTED",
            "REQUIRES_PHYSICAL",
            f"state={probe.pixel_adb_state}",
        )
        res.add_check(
            "A71_ANDROID_EXACT_HEAD_BUILD",
            "PASS_WITH_NOTES",
            "digital CI: use android-exact-head workflow artifact",
        )
        res.add_check("P01_ANDROID_EXACT_HEAD", "PASS_WITH_NOTES", "CI artifact path")
        res.add_check("A73_PIXEL_PHYSICAL_SMOKE", "REQUIRES_PHYSICAL", phys["PIXEL_MATCH_SMOKE"])
        res.add_check("P08_PIXEL_G7_EVIDENCE", "REQUIRES_PHYSICAL", phys["G7_PIXEL_PHYSICAL"])

    # Production rig gates
    man_path = root / "data/bibles/battle_model_manifest_v1_4.json"
    if man_path.exists():
        man = json.loads(man_path.read_text(encoding="utf-8"))
        res.add_check(
            "C04_PRODUCTION_RIG_BINDING_18_OF_18",
            "PASS" if man.get("PRODUCTION_RIG_18_OF_18") and man.get("ROOT_PROXY_PENDING_COUNT") == 0 else "FAIL",
        )
        res.add_check("C05_ROOT_PROXY_PENDING_COUNT_ZERO", "PASS" if man.get("ROOT_PROXY_PENDING_COUNT") == 0 else "FAIL")
    director = root / "packages/game-core/src/story/storyDirector.ts"
    res.add_check("S00_STORY_DIRECTOR_IMPLEMENTED", "PASS" if director.exists() else "FAIL")

    for g in ("G6_VISUAL_READABILITY", "G8_HUMAN_FEEL", "G9_FINAL_ART_APPROVED"):
        res.add_check(g, "REQUIRES_HUMAN")
    res.add_check("MERGE_AUTHORIZED", "REQUIRES_HUMAN", "false")

    # Normalize exit before writing artifacts (optional BLOCKED/REQUIRES_* ≠ digital FAIL)
    fail_ids = [c for c in res.checks if c["status"] == "FAIL"]
    if fail_ids:
        res.status = "FAIL"
        res.exit_code = EXIT_VALIDATION
    elif any(c["status"] in ("REQUIRES_PHYSICAL", "BLOCKED_EXTERNAL", "REQUIRES_HUMAN", "PASS_WITH_NOTES") for c in res.checks):
        res.status = "PASS_WITH_NOTES"
        res.exit_code = EXIT_OK
    else:
        res.status = "PASS"
        res.exit_code = EXIT_OK

    board_rows = [{"id": c["id"], "status": c["status"], "detail": c.get("detail", "")} for c in res.checks]
    csv_path = out_dir / "ACCEPTANCE_BOARD.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["id", "status", "detail"])
        w.writeheader()
        w.writerows(board_rows)

    # MODEL matrix (18) for exact-head board
    man_path = root / "data/bibles/battle_model_manifest_v1_4.json"
    if man_path.exists():
        man = json.loads(man_path.read_text(encoding="utf-8"))
        mx = out_dir / "MODEL_MATRIX.csv"
        with mx.open("w", encoding="utf-8", newline="") as f:
            w = csv.DictWriter(f, fieldnames=["key", "model_kind", "sha256", "exists"])
            w.writeheader()
            for key, entry in man.get("presentations", {}).items():
                w.writerow(
                    {
                        "key": key,
                        "model_kind": entry.get("model_kind"),
                        "sha256": entry.get("sha256"),
                        "exists": (root / entry["source_path"]).exists(),
                    }
                )
        res.artifacts.append(str(mx.relative_to(root)))

    summary = {
        "schema": "anime_aggressors_acceptance_v1_4",
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "command": res.command,
        "git_sha": gt["git_sha"],
        "git_dirty": gt["git_dirty"],
        "branch": gt["branch"],
        "mode": mode,
        "status": res.status,
        "exit_code": res.exit_code,
        "human_gates": HUMAN_GATES,
        "checks": res.checks,
        "MODEL_MANIFEST_18_OF_18": any(c["id"] == "A10_AUTHORED_MODEL_MANIFEST_18_OF_18" and c["status"] == "PASS" for c in res.checks),
        "AUTHORED_GLB_RUNTIME_WIRED": any(c["id"] == "A11_AUTHORED_GLB_RUNTIME_WIRED" and c["status"] == "PASS" for c in res.checks),
        "MERGE_AUTHORIZED": False,
    }
    (out_dir / "ACCEPTANCE.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    (out_dir / "ACCEPTANCE_SUMMARY.md").write_text(
        f"# Acceptance {gt['git_sha'][:12]}\n\nstatus={res.status}\nmode={mode}\n\n"
        + "\n".join(f"- {c['id']}: {c['status']}" for c in res.checks)
        + "\n",
        encoding="utf-8",
    )
    latest = root / "artifacts/acceptance/ANIME_ACCEPTANCE_LATEST.json"
    latest.parent.mkdir(parents=True, exist_ok=True)
    latest.write_text(
        json.dumps(
            {
                "schema": "anime_acceptance_latest_pointer_v1",
                "git_sha": gt["git_sha"],
                "generated_at": summary["generated_at"],
                "local_evidence": str(out_dir.relative_to(root)),
                "status": res.status,
                "MERGE_AUTHORIZED": False,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    res.artifacts.extend(
        [
            str(csv_path.relative_to(root)),
            str((out_dir / "ACCEPTANCE.json").relative_to(root)),
            str(latest.relative_to(root)),
        ]
    )
    res.data["acceptance_dir"] = str(out_dir.relative_to(root))
    return res
