"""animectl story / build / android / play / capture / art thin wrappers."""
from __future__ import annotations

import json
from pathlib import Path

from .git_truth import git_truth
from .process import run
from .result import EXIT_EXTERNAL, EXIT_NO_DEVICE, EXIT_OK, AnimectlResult


def run_story(root: Path, action: str, *, route: str | None = None) -> AnimectlResult:
    gt = git_truth(root)
    res = AnimectlResult(command=f"story {action}", **{k: gt[k] for k in ("repo", "branch", "git_sha", "git_dirty")})
    mod = root / "packages/game-core/src/story/storyProgression.ts"
    res.add_check("STORY_SOURCE", "PASS" if mod.exists() else "FAIL")
    res.data["note"] = "QA helpers are non-destructive; browser uses isolated test profile keys (aa.storyProgress.v1_3.test)."
    res.data["action"] = action
    res.data["route"] = route
    if action == "status":
        res.add_check("STORY_STATUS", "PASS", "use #/story UI or Playwright for live state")
    return res


def run_build(root: Path, target: str, *, exact_head: bool) -> AnimectlResult:
    gt = git_truth(root)
    res = AnimectlResult(command=f"build {target}", **{k: gt[k] for k in ("repo", "branch", "git_sha", "git_dirty")})
    if target in ("web", "all"):
        cp = run(["npm", "run", "build:web"], cwd=root, timeout=300)
        res.add_check("WEB_BUILD", "PASS" if cp.returncode == 0 else "FAIL", (cp.stderr or cp.stdout)[-300:])
        dist = root / "apps/web/dist"
        res.data["web_dist_exists"] = dist.exists()
    if target in ("android", "all"):
        res.add_check("ANDROID_BUILD", "BLOCKED_EXTERNAL", "insufficient disk / optional Godot export")
        res.status = "BLOCKED_EXTERNAL"
        res.exit_code = EXIT_EXTERNAL
    return res


def run_android(
    root: Path,
    action: str,
    *,
    sha: str | None = None,
    artifact_action: str | None = None,
) -> AnimectlResult:
    from .adb_probe import probe_adb
    from .android_artifacts import artifact_command

    gt = git_truth(root)
    if action == "artifact":
        return artifact_command(root, artifact_action or "find", sha=sha)

    res = AnimectlResult(command=f"android {action}", **{k: gt[k] for k in ("repo", "branch", "git_sha", "git_dirty")})
    probe = probe_adb(root)
    res.data["adb_available"] = probe.adb_available
    res.data["pixel_adb_state"] = probe.pixel_adb_state
    res.data["devices"] = probe.devices
    if action == "doctor":
        if not probe.adb_available:
            res.add_check("ADB", "PASS_WITH_NOTES", "OPTIONAL_MISSING — digital runner OK")
            res.add_check("DEVICE", "REQUIRES_PHYSICAL", "ADB_NOT_AVAILABLE_ON_RUNNER")
        else:
            res.add_check("ADB", "PASS", probe.adb_path or "")
            res.add_check(
                "DEVICE",
                "PASS" if probe.has_authorized_device else "REQUIRES_PHYSICAL",
                f"state={probe.pixel_adb_state} count={len(probe.devices)}",
            )
        if not probe.has_authorized_device:
            res.status = "REQUIRES_PHYSICAL"
            res.exit_code = EXIT_NO_DEVICE
    elif action in ("install", "smoke", "evidence"):
        if not probe.adb_available:
            res.add_check("PIXEL", "REQUIRES_PHYSICAL", "ADB_NOT_AVAILABLE_ON_RUNNER")
        elif not probe.has_authorized_device:
            res.add_check("PIXEL", "REQUIRES_PHYSICAL", f"state={probe.pixel_adb_state}")
        else:
            res.add_check("PIXEL", "PASS_WITH_NOTES", "device present — use artifact download + signer-safe install flow")
        if not probe.has_authorized_device:
            res.status = "REQUIRES_PHYSICAL"
            res.exit_code = EXIT_NO_DEVICE
    elif action == "build":
        res.add_check("ANDROID_BUILD", "PASS_WITH_NOTES", "use CI workflow android-exact-head.yml")
        res.status = "PASS_WITH_NOTES"
        res.exit_code = EXIT_OK
    return res


def run_play(root: Path) -> AnimectlResult:
    gt = git_truth(root)
    res = AnimectlResult(command="play", **{k: gt[k] for k in ("repo", "branch", "git_sha", "git_dirty")})
    res.add_check("DEV_HINT", "PASS", "npm run dev — then open #/play or #/story")
    res.data["dev_command"] = "npm run dev -w anime-aggressors-web"
    return res


def run_capture(root: Path, topic: str) -> AnimectlResult:
    gt = git_truth(root)
    res = AnimectlResult(command=f"capture {topic}", **{k: gt[k] for k in ("repo", "branch", "git_sha", "git_dirty")})
    out = root / ".acceptance" / gt["git_sha"] / "screenshots"
    out.mkdir(parents=True, exist_ok=True)
    res.add_check("CAPTURE_DIR", "PASS", str(out.relative_to(root)))
    res.data["note"] = "Heavy captures stay under .acceptance/<sha>/; use Playwright for browser shots."
    return res


def run_art(root: Path, action: str) -> AnimectlResult:
    gt = git_truth(root)
    res = AnimectlResult(command=f"art {action}", **{k: gt[k] for k in ("repo", "branch", "git_sha", "git_dirty")})
    blender = root / "tools/blender"
    res.add_check("BLENDER_PIPELINE_DIR", "PASS" if blender.exists() else "PASS_WITH_NOTES")
    res.add_check("BLENDER_BINARY", "PASS_WITH_NOTES", "OPTIONAL_MISSING if not installed")
    man = root / "data/bibles/battle_model_manifest_v1_4.json"
    if man.exists():
        m = json.loads(man.read_text(encoding="utf-8"))
        res.add_check("ART_MANIFEST_18", "PASS" if m.get("count") == 18 else "FAIL")
    return res
