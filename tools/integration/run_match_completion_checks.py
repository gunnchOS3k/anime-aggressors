"""Bounded internal/public-asset engine checks in a fresh, isolated APFS clone.

No private volume access, movie, forced native result, export or owner save writes.
Headless lifecycle fixtures and native ordinary-input checks have separate scopes.
"""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/v1_closure"))
from native_recording_guard import active_media_jobs


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def owner_state():
    owner = Path.home() / "Library/Application Support/Godot/app_userdata/Anime Aggressors"
    return {str(p.relative_to(owner)): sha(p) for p in owner.rglob("*") if p.is_file()} if owner.exists() else {}


def run(args):
    output = args.output.resolve()
    cached = args.reuse_imported.resolve()
    if output.exists():
        raise ValueError("Use a new label; preserve previous evidence")
    receipt = json.loads((cached.parent / "SOURCE.json").read_text())
    if not cached.is_relative_to(ROOT / "outputs") or receipt.get("private_assets_installed") is not False or not (cached / ".godot/imported").is_dir():
        raise ValueError("Only existing public-resource imports in this candidate are allowed")
    subprocess.run(["git", "merge-base", "--is-ancestor", receipt["source_head"], "HEAD"], cwd=ROOT, check=True)
    if active_media_jobs():
        raise ValueError("Competing media job; leave it untouched")
    allocation = (1636 if args.native else 512) * 2**20
    free = shutil.disk_usage(ROOT).free
    required = max(19 * 2**30, 18 * 2**30 + allocation)
    if free < required:
        raise ValueError(f"Resource forecast unmet: available={free}, required={required}, deficit={required-free}")
    memory = subprocess.check_output(["memory_pressure", "-Q"], text=True)
    percent = int(re.search(r"free percentage: (\d+)%", memory).group(1))
    if percent < 20:
        raise ValueError("Memory pressure guard: below 20% free")
    output.mkdir(parents=True)
    project = output / "game-godot"
    subprocess.run(["/bin/cp", "-cR", str(cached), str(project)], check=True)
    paths = subprocess.check_output(["git", "ls-files", "game-godot"], cwd=ROOT, text=True).splitlines()
    # Include the newly authored focused runner before its first checkpoint.
    paths += [str(p.relative_to(ROOT)) for p in (ROOT / "game-godot/tests/integration").glob("*.gd")]
    hashes = {}
    for rel in sorted(set(paths)):
        source = ROOT / rel
        if not source.is_file():
            continue
        destination = project / source.relative_to(ROOT / "game-godot")
        if not destination.exists() or sha(source) != sha(destination):
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)
        if source.suffix == ".gd":
            hashes[rel] = sha(source)
    name = "aa-native-" + output.name
    config = (project / "project.godot").read_text()
    config = re.sub(r'^config/(?:name|use_custom_user_dir|custom_user_dir_name)=.*\n', '', config, flags=re.M)
    config = config.replace('[application]', '[application]\nconfig/name="'+name+'"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="'+name+'"', 1)
    (project / "project.godot").write_text(config)
    before = owner_state()
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    diff = subprocess.check_output(["git", "diff", "HEAD"], cwd=ROOT)
    (project / "data/runtime/build_identity.json").write_text(json.dumps({
        "git_sha":head,"git_sha_short":head[:12],"git_short_sha":head[:12],
        "watermark":"INTEGRATED "+head[:12],"build_flavor":"isolated-match-completion-review",
        "source_diff_sha256":hashlib.sha256(diff).hexdigest()},indent=2)+"\n")
    (output / "SOURCE.patch").write_bytes(diff)
    record = {"source_head":head,"source_diff_sha256":hashlib.sha256(diff).hexdigest(),
              "source_gd_hashes":hashes,"private_assets_installed":False,"private_storage_accessed":False,
              "user_identity":name,"scope":"native no-movie ordinary-input review" if args.native else "headless technical lifecycle fixture; no gameplay acceptance",
              "available_before_bytes":free,"allocation_forecast_bytes":allocation,
              "required_start_bytes":required,"memory_free_before_percent":percent}
    (output / "SOURCE.json").write_text(json.dumps(record, indent=2)+"\n")
    command = [str(args.godot), "--log-file", str(output / "engine.log"), "--path", str(project),
               "--rendering-method", "gl_compatibility", "--fixed-fps", "60",
               "--script", "res://"+args.script, "--", "--ordinary-output="+str(output),
               "--review-output="+str(output)]
    if args.script == "tests/integration/PlayableMatchReview.gd":
        command += ["--review-fighter=kaia-windrow", "--review-opponent=juno-spark"]
    if args.replay_source:
        replay_source=args.replay_source.resolve()
        if not replay_source.is_relative_to(ROOT / "outputs") or not replay_source.is_file():
            raise ValueError("Replay source must be retained internal candidate evidence")
        prior=json.loads((replay_source.parent / "SOURCE.json").read_text())
        if prior.get("private_assets_installed") is not False:
            raise ValueError("Only recorded public-model gameplay may be replayed here")
        for rel, expected in prior["source_gd_hashes"].items():
            if rel.startswith("game-godot/scripts/") and sha(ROOT / rel)!=expected:
                raise ValueError("Gameplay source differs from recorded input: "+rel)
        record["replay_source_sha256"]=sha(replay_source)
        command += ["--replay-source="+str(replay_source)]
    if args.native:
        command[1:1] = ["--windowed", "--resolution", "1280x720"]
    else:
        command[1:1] = ["--headless", "--audio-driver", "Dummy"]
    record["command"] = command
    # Cloning/refreshing source takes time. Recheck the unchanged forecast
    # immediately before execution, not only at the beginning of preparation.
    launch_free = shutil.disk_usage(ROOT).free
    record["available_at_launch_bytes"] = launch_free
    if launch_free < required or active_media_jobs():
        record.update(guard_stop="prelaunch_resource_or_competing_job", exit_code=None)
        record["pass"] = False
        (output / "SOURCE.json").write_text(json.dumps(record, indent=2)+"\n")
        print("Prelaunch resource guard refused execution; preserved prepared source")
        return 73
    start = time.monotonic()
    peak = 0
    minimum = free
    stopped = None
    with (output / "stdout.log").open("x") as log:
        child = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT)
        try:
            while child.poll() is None:
                minimum = min(minimum, shutil.disk_usage(ROOT).free)
                usage = subprocess.run(["ps", "-o", "rss=", "-p", str(child.pid)], capture_output=True, text=True)
                if usage.stdout.strip().isdigit():
                    peak = max(peak, int(usage.stdout.strip()) * 1024)
                text = (output / "stdout.log").read_text(errors="replace")
                if "SCRIPT ERROR:" in text or "Parse Error" in text:
                    stopped = "engine_script_error"
                if minimum < 18 * 2**30 or free-minimum > allocation or peak > (1536 if args.native else 600) * 2**20:
                    stopped = "resource_guard"
                if time.monotonic() - start > args.max_seconds:
                    stopped = "time_guard"
                if stopped:
                    break
                time.sleep(.15)
        finally:
            if child.poll() is None:
                child.terminate()
                try: child.wait(8)
                except subprocess.TimeoutExpired: child.kill(); child.wait()
    text = (output / "stdout.log").read_text(errors="replace")
    record.update(exit_code=child.returncode, guard_stop=stopped, seconds=time.monotonic()-start,
                  sampled_peak_rss_bytes=peak, minimum_internal_free_bytes=minimum,
                  available_after_bytes=shutil.disk_usage(ROOT).free,
                  owner_saves_unchanged=before==owner_state(),
                  log_sha256=sha(output / "stdout.log"))
    record["shutdown_diagnostics"] = [line for line in text.splitlines() if "ObjectDB" in line or "resources still in use" in line]
    record["pass"] = child.returncode==0 and stopped is None and record["owner_saves_unchanged"] and "SCRIPT ERROR:" not in text
    (output / "SOURCE.json").write_text(json.dumps(record, indent=2)+"\n")
    print(json.dumps({k:record[k] for k in ("source_head","pass","exit_code","guard_stop","seconds","sampled_peak_rss_bytes","minimum_internal_free_bytes","owner_saves_unchanged")}))
    return 0 if record["pass"] else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--reuse-imported", type=Path, required=True)
    parser.add_argument("--godot", type=Path, default=Path("/Applications/Godot.app/Contents/MacOS/Godot"))
    parser.add_argument("--script", default="tests/integration/MatchFinality.gd")
    parser.add_argument("--native", action="store_true")
    parser.add_argument("--max-seconds", type=int, default=60)
    parser.add_argument("--replay-source", type=Path)
    raise SystemExit(run(parser.parse_args()))
