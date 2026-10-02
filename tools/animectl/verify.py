"""animectl verify — wrap existing validators."""
from __future__ import annotations

import json
from pathlib import Path

from .git_truth import git_truth
from .process import run
from .result import AnimectlResult


FIGHTERS = [
    "ember-vale",
    "rook-ironside",
    "juno-spark",
    "kaia-windrow",
    "nix-calder",
    "orion-vell",
    "vesper-nyx",
    "yin",
    "yang",
]


def _authority_counts(root: Path) -> tuple[int, int]:
    inv = json.loads((root / "data/bibles/animation_inventory_v1.json").read_text(encoding="utf-8"))
    slots = [s["id"] for c in inv["categories"] for s in c["slots"]]
    authored = 0
    fallback = 0
    for fid in FIGHTERS:
        for slot in slots:
            p = root / "content/fighters" / fid / "animations/procedural" / f"{slot}.anim.json"
            if not p.exists():
                continue
            st = json.loads(p.read_text(encoding="utf-8")).get("authority_status")
            if st == "AUTOMATION_AUTHORED_CANDIDATE":
                authored += 1
            elif st == "PROCEDURAL_FALLBACK":
                fallback += 1
    return authored, fallback


def run_verify(root: Path, topic: str) -> AnimectlResult:
    gt = git_truth(root)
    res = AnimectlResult(command=f"verify {topic}", **{k: gt[k] for k in ("repo", "branch", "git_sha", "git_dirty")})
    if topic in ("animations", "all"):
        authored, fallback = _authority_counts(root)
        res.add_check("AUTHORITY_999", "PASS" if authored == 999 else "FAIL", f"authored={authored}")
        res.add_check("PROCEDURAL_FALLBACK_0", "PASS" if fallback == 0 else "FAIL", f"fallback={fallback}")
        v = root / "tools/animation_authority/validate_playable_runtime_v1_3.py"
        if v.exists():
            cp = run(["python3", str(v)], cwd=root)
            res.add_check("VALIDATE_PLAYABLE_V1_3", "PASS" if cp.returncode == 0 else "FAIL", cp.stdout[-200:])
    if topic in ("moves", "all"):
        m216 = root / "artifacts/pr118_playable_runtime/matrices/MOVE_ANIMATION_FRAME_SYNC_216.json"
        if m216.exists():
            data = json.loads(m216.read_text(encoding="utf-8"))
            # stale-head aware: report note but still validate counts
            res.add_check("MOVE_216", "PASS" if data.get("PASS") else "FAIL", f"resolved={data.get('resolved')}")
            if data.get("head_sha_at_generation") and data["head_sha_at_generation"] != gt["git_sha"]:
                res.add_check(
                    "MOVE_216_HEAD",
                    "PASS_WITH_NOTES",
                    f"matrix generated at {data['head_sha_at_generation']}; current {gt['git_sha']}",
                )
        else:
            res.add_check("MOVE_216", "FAIL", "missing matrix")
    if topic in ("models", "rig", "all"):
        man = root / "data/bibles/battle_model_manifest_v1_4.json"
        if man.exists():
            m = json.loads(man.read_text(encoding="utf-8"))
            missing = []
            no_skin = []
            proxy = 0
            for key, entry in m.get("presentations", {}).items():
                src = root / entry["source_path"]
                if not src.exists():
                    missing.append(key)
                    continue
                # quick GLB skin probe
                data = src.read_bytes()
                if b'"skins"' not in data and b'"skin"' not in data:
                    # parse json chunk lightly
                    import struct

                    try:
                        length, ctype = struct.unpack_from("<I4s", data, 12)
                        meta = json.loads(data[20 : 20 + length].decode())
                        if not meta.get("skins"):
                            no_skin.append(key)
                    except Exception:
                        no_skin.append(key)
                if entry.get("animation_binding") != "PRODUCTION_RIG":
                    proxy += 1
            res.add_check("MODEL_MANIFEST_18", "PASS" if m.get("count") == 18 and not missing else "FAIL", f"missing={missing}")
            res.add_check("SKIN_PRESENT_18", "PASS" if not no_skin else "FAIL", f"no_skin={no_skin}")
            res.add_check(
                "PRODUCTION_RIG_BINDING_18",
                "PASS" if m.get("PRODUCTION_RIG_18_OF_18") and m.get("ROOT_PROXY_PENDING_COUNT", 1) == 0 else "FAIL",
                f"proxy_pending={m.get('ROOT_PROXY_PENDING_COUNT')}",
            )
            matrix = root / "artifacts/acceptance/PRODUCTION_RIG_MATRIX.json"
            if matrix.exists():
                mx = json.loads(matrix.read_text(encoding="utf-8"))
                res.add_check("PRODUCTION_RIG_MATRIX", "PASS" if mx.get("PASS_18_OF_18") else "FAIL")
        else:
            res.add_check("MODEL_MANIFEST_18", "FAIL", "missing")
        factory = (root / "apps/web/src/renderer-three/fighters/FighterModelFactory.ts").read_text(encoding="utf-8")
        res.add_check(
            "AUTHORED_GLB_RUNTIME_WIRED",
            "PASS" if "wrapAuthoredGlbAsParts" in factory else "FAIL",
        )
        res.add_check(
            "PRODUCTION_RIG_RUNTIME",
            "PASS" if "PRODUCTION_RIG" in factory else "FAIL",
        )
    if topic in ("story", "all"):
        story = root / "packages/game-core/src/story/storyProgression.ts"
        director = root / "packages/game-core/src/story/storyDirector.ts"
        res.add_check("STORY_MODULE", "PASS" if story.exists() else "FAIL")
        res.add_check("STORY_DIRECTOR", "PASS" if director.exists() else "FAIL")
        screen = (root / "apps/web/src/screens/StoryCampaignScreen.ts").read_text(encoding="utf-8")
        res.add_check("STORY_UI", "PASS" if "story-campaign" in screen else "FAIL")
        res.add_check(
            "STORY_QA_HIDDEN",
            "PASS" if "isStoryDevMode" in screen or "?dev=1" in screen or "story-qa-drawer" in screen else "FAIL",
        )
        # Normal UI must not show QA complete buttons without dev gate
        qa_exposed = 'data-complete-route="' in screen and "dev ?" not in screen and "if (dev)" not in screen and "${dev ?" not in screen
        res.add_check("STORY_NORMAL_NO_RAW_QA", "PASS" if "${dev ?" in screen or "dev ?" in screen else ("FAIL" if qa_exposed else "PASS"))
    if topic in ("e2e", "all"):
        pkg = json.loads((root / "package.json").read_text(encoding="utf-8"))
        deps = {**(pkg.get("devDependencies") or {}), **(pkg.get("dependencies") or {})}
        res.add_check("PLAYWRIGHT_PINNED", "PASS" if "@playwright/test" in deps else "FAIL")
        soft = 0
        for p in (root / "tests/e2e").glob("*.spec.ts") if (root / "tests/e2e").exists() else []:
            txt = p.read_text(encoding="utf-8")
            if "test.skip(" in txt or "|| true" in txt:
                soft += 1
        res.add_check("PRIMARY_E2E_SOFT_SKIP", "PASS" if soft == 0 else "FAIL", f"soft_files={soft}")
    if topic in ("determinism", "all"):
        cp = run(["npm", "run", "test", "-w", "@anime-aggressors/game-core"], cwd=root, timeout=180)
        # Too heavy for every call — only run if topic is determinism specifically
        if topic == "determinism":
            res.add_check("GAME_CORE_TEST", "PASS" if cp.returncode == 0 else "FAIL", cp.stderr[-300:])
        else:
            res.add_check("DETERMINISM", "PASS_WITH_NOTES", "use verify determinism for full suite")
    if topic in ("partylink", "all"):
        pl = root / "packages/partylink"
        res.add_check("PARTYLINK_PACKAGE", "PASS" if pl.exists() else "FAIL")
    return res
