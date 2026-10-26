"""Software-only checks in the existing PUBLIC standard Linux Actions environment.

Not a local resource-guard bypass, art producer, native visual/device test or
earned-campaign acceptance. No private artifacts, owner saves or build exports.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def guard():
    if not (os.environ.get("GITHUB_ACTIONS") == "true"
            and os.environ.get("RUNNER_ENVIRONMENT") == "github-hosted"
            and os.environ.get("RUNNER_OS") == "Linux"
            and os.environ.get("GITHUB_REPOSITORY") == "gunnchOS3k/anime-aggressors"):
        raise RuntimeError("Only the existing public hosted Linux CI environment is supported; use guarded local runners locally")
    free = shutil.disk_usage(ROOT).free
    # Dedicated disposable software-test runner:2GiB forecast +2GiB reserve.
    # This is NOT the owner's Mac. Its19/18GiB local production guards remain
    # in the local runner and are not changed or selectable through this tool.
    if free < 4 * 2**30:
        raise RuntimeError(f"CI storage forecast unmet: available={free}, required={4 * 2**30}")
    memory = dict(re.findall(r"^(MemTotal|MemAvailable):\s+(\d+)", Path("/proc/meminfo").read_text(), re.M))
    if int(memory["MemAvailable"]) < int(memory["MemTotal"]) * .2:
        raise RuntimeError("CI memory availability below20%")
    return free


def execute(command, log, deadline=120):
    guard()
    started = time.monotonic()
    stop = None
    peak = 0
    with log.open("x") as stream:
        child = subprocess.Popen(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT)
        while child.poll() is None:
            status = Path(f"/proc/{child.pid}/status")
            if status.exists():
                match = re.search(r"^VmRSS:\s+(\d+)", status.read_text(), re.M)
                if match: peak = max(peak, int(match[1]) * 1024)
            if time.monotonic() - started > deadline: stop = "time_guard"
            if shutil.disk_usage(ROOT).free < 2 * 2**30: stop = "CI_storage_reserve"
            if peak > 4 * 2**30: stop = "process_memory_guard"
            if log.stat().st_size > 8 * 2**20: stop = "log_limit"
            if "SCRIPT ERROR:" in log.read_text(errors="replace"): stop = "engine_script_error"
            if stop:
                child.terminate()
                try: child.wait(5)
                except subprocess.TimeoutExpired: child.kill(); child.wait()
                break
            time.sleep(.1)
    text = log.read_text(errors="replace")
    lines = text.splitlines()
    errors = ["\n".join(lines[i:i+3]) for i, line in enumerate(lines) if "SCRIPT ERROR:" in line or "Parse Error" in line]
    return {"exit_code": child.returncode, "guard_stop": stop, "seconds": time.monotonic()-started,
            "sampled_peak_rss_bytes": peak, "script_errors": errors[:30], "log_sha256": sha(log),
            "PASS": child.returncode == 0 and not stop and not errors}


def run(output, suite_set="training-story"):
    output.mkdir(parents=True, exist_ok=False)
    record = {"PASS": False, "scope": "Real headless Godot public-resource scene tests, not native visual/art/device/earned-route acceptance", "suites": {}}
    try:
        record["available_start_bytes"] = guard()
        head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
        if head != os.environ.get("GITHUB_SHA"): raise RuntimeError("Exact source SHA mismatch")
        record["source_head"] = head
        record["source_sha256"] = {str(path.relative_to(ROOT)): sha(path) for path in (ROOT/"game-godot/scripts").rglob("*.gd")}
        godot = os.environ["GODOT_BIN"]
        record["godot_version"] = subprocess.check_output([godot, "--version"], text=True).strip()
        if not record["godot_version"].startswith("4.7.1.stable"): raise RuntimeError("Unexpected Godot verifier")
        project = ROOT/"game-godot/project.godot"
        config = re.sub(r'^config/(?:name|use_custom_user_dir|custom_user_dir_name)=.*\n', '', project.read_text(), flags=re.M)

        def profile(name):
            project.write_text(config.replace('[application]', '[application]\nconfig/name="aa-native-ci-'+name+'"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="aa-native-ci-'+name+'"', 1))

        profile("import")
        base = [godot, "--headless", "--path", str(ROOT/"game-godot"), "--audio-driver", "Dummy", "--rendering-method", "gl_compatibility"]
        imported = execute(base+["--editor", "--import", "--quit"], output/"import.log", 180)
        record["import"] = imported
        if not imported["PASS"]: return record
        suites = [
            ("frame-step", "tests/integration/TrainingFrameStep.gd", "TRAINING_FRAME_STEP.json"),
            ("practice", "tests/integration/TrainingPractice.gd", "TRAINING_PRACTICE.json"),
            ("lifecycle", "tests/integration/TrainingLifecycle.gd", "TRAINING_LIFECYCLE.json"),
            ("story-scenes", "tests/v1_closure/StorySceneOwnership.gd", "story_scene_ownership.json"),
            ("story-save-recovery", "tests/integration/StorySaveRecovery.gd", "STORY_SAVE_RECOVERY.json"),
        ] if suite_set == "training-story" else [
            ("story-play", "tests/integration/ResumedStoryEncounter.gd", "STORY_ENCOUNTER_PLAY.json"),
            ("story-restart", "tests/integration/ResumedStoryEncounter.gd", "STORY_ENCOUNTER_RESTART.json"),
        ]
        if suite_set == "story-controls":
            suites = [("story-controls", "tests/integration/ResumedStoryEncounter.gd", "STORY_ENCOUNTER_CONTROLS.json"),
                      ("lifecycle", "tests/integration/TrainingLifecycle.gd", "TRAINING_LIFECYCLE.json")]
        record["suite_set"] = suite_set
        for name, script, result in suites:
            # A second REAL process reopens the first process's signed save.
            profile("story-encounter" if name.startswith("story-") else name)
            outcome = execute(base+["--fixed-fps", "60", "--script", "res://"+script,
                                   "--", "--ordinary-output="+str(output), "--story-pass="+name], output/(name+".log"))
            path = output/result
            data = json.loads(path.read_text()) if path.exists() else {}
            outcome["result_present"] = path.exists()
            outcome["PASS"] = outcome["PASS"] and bool(data.get("PASS", False))
            outcome["failures"] = data.get("failures", ["Result missing"])
            outcome["checks"] = len(data.get("checks", []))
            outcome["rows"] = len(data.get("rows", []))
            outcome["observations"] = data.get("samples", data.get("observations", []))
            if path.exists(): outcome["result_sha256"] = sha(path)
            record["suites"][name] = outcome
            if suite_set.startswith("story-") and not outcome["PASS"]: break
        record["PASS"] = len(record["suites"]) == len(suites) and all(row["PASS"] for row in record["suites"].values())
    except Exception as error:
        record["error"] = str(error)
    finally:
        (output/"ENGINE_RESULT.json").write_text(json.dumps(record, indent=2)+"\n")
        print(json.dumps(record, indent=2))
    return record


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--suite-set", choices=["training-story", "story-encounter", "story-controls"], default="training-story")
    args = parser.parse_args()
    raise SystemExit(0 if run(args.output, args.suite_set)["PASS"] else 1)
