"""Independent execution of immutable PUBLIC Cursor gameplay source.

No checkout/branch/worktree writes: materialize a bounded Git archive on the
existing disposable public Linux runner. No art production, uploads or exports.
"""
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import tarfile
from run_training_story_ci import ROOT, execute, guard, sha

CURSOR_SHA = "1d7eda52a49cc394d6865353b36034ab11663c41"
MAX_SOURCE_BYTES = 512 * 2**20


def run(base, output, integration_sha):
    guard()
    record = {"PASS": False, "source_head": integration_sha, "verified_cursor_source": CURSOR_SHA,
              "scope": "Independent exact Cursor-source engine verification: three-form rules, declared developer-eligible ordinary Training controls and isolated earned-unlock fixtures. Not an ordinary earned campaign, original-art, native visual, multiplayer, device or human acceptance.",
              "suites": {}, "HUMAN_ART_APPROVED": False, "HUMAN_GAMEPLAY_PASS": False,
              "RC2_READY": False, "V1_0_0_RELEASE_AUTHORIZED": False}
    # Only fetch this already public owner-authored commit. No ref updates or
    # branch checkout; this is a disposable CI clone, never Cursor's worktree.
    missing = subprocess.run(["git", "cat-file", "-e", CURSOR_SHA + "^{commit}"], cwd=ROOT,
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode
    if missing:
        subprocess.run(["git", "fetch", "--no-tags", "--depth=1", "origin", CURSOR_SHA], cwd=ROOT,
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, timeout=90)
    actual = subprocess.check_output(["git", "rev-parse", CURSOR_SHA + "^{commit}"], cwd=ROOT, text=True).strip()
    if actual != CURSOR_SHA:
        raise RuntimeError("Immutable Cursor source mismatch")
    destination = output / "cursor-source"
    destination.mkdir(exist_ok=False)
    archive = subprocess.Popen(["git", "archive", "--format=tar", CURSOR_SHA, "game-godot"],
                               cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    total = 0
    try:
        with tarfile.open(fileobj=archive.stdout, mode="r|") as source:
            for member in source:
                relative = PurePosixPath(member.name)
                if relative.is_absolute() or ".." in relative.parts or not relative.parts or relative.parts[0] != "game-godot":
                    raise RuntimeError("Unsafe source archive path")
                target = destination.joinpath(*relative.parts)
                if member.isdir():
                    target.mkdir(parents=True, exist_ok=True)
                elif member.isfile():
                    total += member.size
                    if total > MAX_SOURCE_BYTES:
                        raise RuntimeError("Cursor source allocation forecast exceeded")
                    target.parent.mkdir(parents=True, exist_ok=True)
                    with source.extractfile(member) as incoming, target.open("xb") as outgoing:
                        while chunk := incoming.read(2**20):
                            outgoing.write(chunk)
                else:
                    raise RuntimeError("Source archive links/devices are not permitted")
        if archive.wait(timeout=10) != 0:
            raise RuntimeError("Immutable source archive failed")
    finally:
        if archive.poll() is None:
            archive.terminate()
            archive.wait(timeout=5)
    record["materialized_source_bytes"] = total
    project_root = destination / "game-godot"
    project = project_root / "project.godot"
    config = re.sub(r'^config/(?:name|use_custom_user_dir|custom_user_dir_name)=.*\n', '', project.read_text(), flags=re.M)
    record["tested_source_sha256"] = {str(path.relative_to(project_root)): sha(path) for path in [
        project, project_root / "scripts/combat/rosamere_form_selection.gd", project_root / "scripts/combat/pink_bloom_systems.gd",
        project_root / "scripts/story/v1_campaign_runtime.gd", project_root / "scripts/fighters/fighter.gd",
        project_root / "data/fighters/rosamere.json", project_root / "data/forms/rosamere.json", project_root / "data/moves/rosamere.json",
    ]}
    # Preserve all gameplay sources. Only ephemeral project identity changes so
    # these tests cannot read regular/owner profiles, even on a reused machine.
    def profile(label):
        identity = "aa-native-ci-independent-rosamere-" + label
        project.write_text(config.replace('[application]', '[application]\nconfig/name="'+identity+'"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="'+identity+'"', 1))
    profile("import")
    engine_base = [base[0], "--headless", "--path", str(project_root), "--audio-driver", "Dummy", "--rendering-method", "gl_compatibility"]
    record["import"] = execute(engine_base + ["--editor", "--import", "--quit"], output / "cursor-import.log", 180)
    if not record["import"]["PASS"]:
        return record
    for name, script, filename in [
        ("forms", "RosamereThreeFormCanon.gd", "ROSAMERE_THREE_FORM_CANON.json"),
        ("controls", "RosamereOrdinaryControlsTraining.gd", "ROSAMERE_ORDINARY_CONTROLS_TRAINING.json"),
        ("unlock", "RosamereStoryUnlock.gd", "ROSAMERE_STORY_UNLOCK.json"),
    ]:
        guard()
        profile(name)
        result_dir = output / ("cursor-" + name)
        result_dir.mkdir(exist_ok=False)
        script_path = project_root / "tests/integration" / script
        outcome = execute(engine_base + ["--fixed-fps", "60", "--script", "res://tests/integration/" + script,
                          "--", "--ordinary-output=" + str(result_dir)], output / ("cursor-" + name + ".log"))
        result_path = result_dir / filename if name != "unlock" else destination / "artifacts/cursor_continuation/ROSAMERE_STORY_UNLOCK_EVIDENCE.json"
        data = json.loads(result_path.read_text()) if result_path.exists() else {}
        passed = bool(data.get("PASS", False)) if name != "unlock" else bool(data.get("ok", False))
        checks = data.get("checks", [])
        outcome.update({"PASS": outcome["PASS"] and passed, "result": data,
                        "checks": len(checks) if isinstance(checks, list) else int(checks), "failures": data.get("failures", ["Missing source fixture result"]),
                        "script_sha256": sha(script_path), "result_sha256": sha(result_path) if result_path.exists() else None})
        record["suites"][name] = outcome
        # A real failure remains a failure; never rewrite Cursor code in order
        # to obtain an independent pass or continue masking parser errors.
        if not outcome["PASS"]:
            break
    record["PASS"] = len(record["suites"]) == 3 and all(row["PASS"] for row in record["suites"].values())
    record["available_end_bytes"] = guard()
    return record
