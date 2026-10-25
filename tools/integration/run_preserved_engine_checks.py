"""Small, source-bound Godot checks. No asset import, cleanup, export or owner save writes.

Copies the reviewed source dependency closure into a NEW probe project and uses a
unique user-directory identity. This is engine/API verification, never BattleScene,
earned Story, physical LAN, packaged-build, device or visual acceptance.
"""
import argparse
import hashlib
import json
import shutil
import subprocess
import time
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def owner_state():
    directory = Path.home() / "Library/Application Support/Godot/app_userdata/Anime Aggressors"
    return {str(p.relative_to(directory)): digest(p) for p in directory.rglob("*") if p.is_file()} if directory.exists() else {}


def run(godot, output, suite="preserved"):
    output = output.resolve()
    if output.exists():
        raise ValueError("Preserve previous results: use a new output directory")
    # These tiny source probes do not meet the definition of heavy production.
    # Allow 64MiB total disk growth; retain the protected18GiB after that forecast.
    allocation = (256 if suite == "recovery-geometry" else 64) * 2**20
    if shutil.disk_usage(ROOT).free < 18 * 2**30 + allocation:
        raise ValueError("Insufficient internal reserve for bounded source checks")
    output.mkdir(parents=True)
    project = output / "project"
    project.mkdir()
    copied = {}
    paths = [ROOT / "game-godot/scripts/core/GameState.gd",
             ROOT / "game-godot/scripts/input/InputPersistenceService.gd",
             ROOT / "game-godot/scripts/combat/competitive_rules.gd",
             ROOT / "game-godot/scripts/combat/combat_outcome.gd",
             ROOT / "game-godot/scripts/story/v1_campaign_runtime.gd",
             ROOT / "game-godot/data/story/v1_campaign.json",
             ROOT / "game-godot/tests/save_rules_roundtrip.gd",
             ROOT / "game-godot/tests/replay_persist_roundtrip.gd",
             ROOT / "game-godot/tests/v1_closure/StorySceneAuthority.gd",
             ROOT / "game-godot/tests/integration/PreservedContracts.gd"]
    paths += sorted((ROOT / "game-godot/scripts/net").glob("*.gd"))
    tests = ["tests/save_rules_roundtrip.gd", "tests/replay_persist_roundtrip.gd",
             "tests/v1_closure/StorySceneAuthority.gd", "tests/integration/PreservedContracts.gd"]
    autoload = ('[autoload]\nGameState="*res://scripts/core/GameState.gd"\n'
                'CampaignRuntime="*res://scripts/story/v1_campaign_runtime.gd"\n')
    if suite == "recovery-geometry":
        # Pure source/API unit tests: no art, cache, imported assets, autoloads,
        # BattleScene or native rendering. Separate 256MiB allocation forecast;
        # the full-scene19GiB start guard is not changed or invoked here.
        paths = [ROOT / "game-godot" / rel for rel in (
            "scripts/fighters/fighter_state_machine.gd", "scripts/fighters/fighter_states.gd",
            "scripts/combat/combat_math.gd", "scripts/combat/combat_space_contract.gd",
            "tests/integration/RecoveryGeometry.gd")]
        for fid in ("ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
                    "nix-calder", "orion-vell", "vesper-nyx", "yin", "yang"):
            paths += [ROOT / "game-godot/data" / folder / (fid+".json") for folder in ("fighters", "moves")]
        tests = ["tests/integration/RecoveryGeometry.gd"]
        autoload = ""
    for source in paths:
        rel = source.relative_to(ROOT / "game-godot")
        dest = project / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, dest)
        copied[str(rel)] = digest(source)
        assert digest(dest) == copied[str(rel)]
    name = "aa-preserved-" + uuid.uuid4().hex
    (project / "project.godot").write_text(
        'config_version=5\n[application]\nconfig/name="' + name + '"\n'
        'config/use_custom_user_dir=true\nconfig/custom_user_dir_name="' + name + '"\n'
        + autoload +
        '[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
    before = owner_state()
    rows = []
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    receipt = {"source_head": head, "source_files": copied, "godot": str(godot),
               "user_directory_identity": name, "scope": __doc__, "suite":suite,
               "allocation_forecast_bytes":allocation, "rows": rows}
    for test in tests:
        label = Path(test).stem
        log = output / (label + ".log")
        command = [str(godot), "--headless", "--audio-driver", "Dummy", "--path", str(project),
                   "--script", "res://" + test, "--", "--ordinary-output=" + str(output)]
        start = time.monotonic()
        peak = 0
        minimum = shutil.disk_usage(ROOT).free
        stopped = None
        with log.open("w") as stream:
            process = subprocess.Popen(command, stdout=stream, stderr=subprocess.STDOUT)
            try:
                while process.poll() is None:
                    minimum = min(minimum, shutil.disk_usage(ROOT).free)
                    if "SCRIPT ERROR:" in log.read_text(errors="replace"):
                        stopped = "script_error"
                        break
                    rss = subprocess.run(["ps", "-o", "rss=", "-p", str(process.pid)], capture_output=True, text=True)
                    if rss.stdout.strip().isdigit():
                        peak = max(peak, int(rss.stdout.strip()) * 1024)
                    if minimum < 18 * 2**30 or peak > (256 if suite=="recovery-geometry" else 400) * 2**20 or time.monotonic() - start > 45:
                        stopped = "resource_or_time_guard"
                        break
                    time.sleep(.1)
            finally:
                if process.poll() is None:
                    process.terminate()
                    try:
                        process.wait(5)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
        text = log.read_text(errors="replace")
        failed = any(x in text for x in ("SCRIPT ERROR:", "ERROR: Failed to load script", "FAIL", "Parse Error"))
        row = {"test": test, "command": command, "exit_code": process.returncode,
               "pass": process.returncode == 0 and not failed and stopped is None,
               "guard_stop": stopped, "seconds": time.monotonic()-start,
               "sampled_peak_rss_bytes": peak, "minimum_internal_free_bytes": minimum,
               "log_sha256": digest(log)}
        rows.append(row)
        receipt["owner_save_files_unchanged"] = before == owner_state()
        (output / "RESULTS.json").write_text(json.dumps(receipt, indent=2) + "\n")
        print(label, "PASS" if row["pass"] else "FAIL", flush=True)
        if stopped or not receipt["owner_save_files_unchanged"]:
            break
    return all(x["pass"] for x in rows) and len(rows) == len(tests) and before == owner_state()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--suite", choices=("preserved", "recovery-geometry"), default="preserved")
    args = parser.parse_args()
    raise SystemExit(0 if run(args.godot, args.output, args.suite) else 1)
