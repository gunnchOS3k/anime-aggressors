"""Run the actual integrated game in a NEW APFS-cloned, isolated review project.

Public repository assets only. Private asset production/injection has its separate
encrypted-storage gate and is not bypassed by this internal gameplay review.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/v1_closure"))
from native_recording_guard import budget, run_owned_recording, active_media_jobs


def run(args):
    output = args.output.resolve()
    if output.exists(): raise ValueError("Preserve existing outputs; use a new label")
    movie = output / "native_match_60fps.avi"
    storage = budget(ROOT, movie, args.frames, 60)
    # Additional allowance for the fresh Godot import/cache and possible swap.
    # First measured native run consumed about1.16GiB including its movie.
    # Keep1.5GiB for import/GPU/swap in addition to the existing movie budget.
    storage["import_and_swap_forecast_bytes"] = 1536 * 2**20
    free = shutil.disk_usage(ROOT).free
    if free < max(19*2**30, storage["required_free_bytes"] + storage["import_and_swap_forecast_bytes"]):
        raise ValueError("19GiB start /18GiB after capture+import+swap forecast not met")
    if active_media_jobs(): raise ValueError("Existing media process preserved")
    output.mkdir(parents=True)
    project = output / "game-godot"
    # APFS copy-on-write. Never move/clean/write the original checkout or caches.
    source = ROOT / "game-godot"
    imported = getattr(args, "reuse_imported", None)
    if imported:
        imported = imported.resolve()
        receipt = json.loads((imported.parent / "SOURCE.json").read_text())
        if not imported.is_relative_to(ROOT / "outputs") or receipt.get("private_assets_installed") is not False or not (imported / ".godot/imported").is_dir():
            raise ValueError("Only this candidate's existing public-asset import may be reused")
        subprocess.run(["git", "merge-base", "--is-ancestor", receipt["source_head"], "HEAD"], cwd=ROOT, check=True)
    subprocess.run(["/bin/cp", "-cR", str(imported or source), str(project)], check=True)
    if imported:
        # Keep the imported public resources; refresh ALL tracked source from
        # this candidate, rather than running stale code from the earlier movie.
        for relative in subprocess.check_output(["git", "ls-files", "game-godot"], cwd=ROOT, text=True).splitlines():
            current = ROOT / relative
            if not current.is_file(): continue
            destination = project / current.relative_to(source)
            if not destination.exists() or current.read_bytes() != destination.read_bytes():
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(current, destination)
    config = (project / "project.godot").read_text()
    name = "aa-native-"+output.name
    config = re.sub(r'^config/(?:name|use_custom_user_dir|custom_user_dir_name)=.*\n', '', config, flags=re.M)
    config = config.replace('[application]', '[application]\nconfig/name="'+name+'"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="'+name+'"', 1)
    (project / "project.godot").write_text(config)
    identity = project / "data/runtime/build_identity.json"
    head = subprocess.check_output(["git","rev-parse","HEAD"], cwd=ROOT, text=True).strip()
    identity.write_text(json.dumps({"git_sha":head,"git_sha_short":head[:12],"git_short_sha":head[:12],"watermark":"INTEGRATED "+head[:12],"build_flavor":"isolated-native-source-review"},indent=2)+'\n')
    godot = str(args.godot)
    env = os.environ.copy()
    owner = Path.home()/"Library/Application Support/Godot/app_userdata/Anime Aggressors"
    before = {str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in owner.rglob("*") if p.is_file()} if owner.exists() else {}
    manifest = {"source_head":head,"source_diff_sha256":hashlib.sha256(subprocess.check_output(["git","diff","HEAD"],cwd=ROOT)).hexdigest(),"project":str(project),"user_identity":name,"storage":storage,"private_assets_installed":False,"owner_saves_before":before}
    (output/"SOURCE.json").write_text(json.dumps(manifest,indent=2)+'\n')
    if imported:
        manifest["reused_public_import"] = str(imported)
        manifest["import"] = {"scope":"Existing public resource cache reused; current tracked source refreshed. No fresh import claim."}
        (output/"SOURCE.json").write_text(json.dumps(manifest,indent=2)+'\n')
        return capture(args, output, project, movie, godot, owner, before, manifest)
    start = time.monotonic();peak=0;minimum=free
    with (output/"import.log").open("x") as log:
        child=subprocess.Popen([godot,"--headless","--editor","--import","--path",str(project),"--quit"],stdout=log,stderr=subprocess.STDOUT,env=env)
        try:
            while child.poll() is None:
                available=shutil.disk_usage(ROOT).free;minimum=min(minimum,available)
                p=subprocess.run(["ps","-o","rss=","-p",str(child.pid)],capture_output=True,text=True)
                if p.stdout.strip().isdigit():peak=max(peak,int(p.stdout.strip())*1024)
                if available < storage["required_free_bytes"] or peak > 1.5*2**30 or time.monotonic()-start > 180:
                    raise RuntimeError("Bounded import resource guard")
                time.sleep(.3)
        finally:
            if child.poll() is None:
                child.terminate()
                try:child.wait(8)
                except subprocess.TimeoutExpired:child.kill();child.wait()
    text=(output/"import.log").read_text(errors="replace")
    manifest["import"]={"exit_code":child.returncode,"sampled_peak_RSS_bytes":peak,"minimum_internal_free_bytes":minimum,"seconds":time.monotonic()-start}
    (output/"SOURCE.json").write_text(json.dumps(manifest,indent=2)+'\n')
    if child.returncode or "SCRIPT ERROR:" in text or "Parse Error" in text:
        raise RuntimeError("Actual import failed; retain logs and repair source")
    return capture(args, output, project, movie, godot, owner, before, manifest)


def capture(args, output, project, movie, godot, owner, before, manifest):
    if args.import_only: return 0
    if shutil.disk_usage(ROOT).free < 19*2**30:
        raise RuntimeError("Post-import19GiB start guard failed; preserve import, defer capture")
    command=[godot,"--path",str(project),"--rendering-method","gl_compatibility","--windowed","--resolution","1280x720","--write-movie",str(movie),"--fixed-fps","60","--quit-after",str(args.frames),"--script","res://tests/integration/PlayableMatchReview.gd","--","--review-output="+str(output)]
    if not args.manual: command.append("--review-automate")
    if args.female: command.append("--review-female")
    command[1:1]=["--log-file",str(output/"native.log")]
    result=run_owned_recording(command,ROOT,movie,output,budget(ROOT,movie,args.frames,60),error_log=output/"native.log")
    after={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in owner.rglob("*") if p.is_file()} if owner.exists() else {}
    manifest["owner_saves_unchanged"]=before==after
    manifest["native_exit"]=result
    (output/"SOURCE.json").write_text(json.dumps(manifest,indent=2)+'\n')
    if before != after: raise RuntimeError("Owner-save protection failed")
    return result


if __name__ == "__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output",type=Path,required=True)
    parser.add_argument("--godot",type=Path,default=Path("/Applications/Godot.app/Contents/MacOS/Godot"))
    parser.add_argument("--frames",type=int,default=1200)
    parser.add_argument("--female",action="store_true")
    parser.add_argument("--manual",action="store_true")
    parser.add_argument("--import-only",action="store_true")
    parser.add_argument("--reuse-imported",type=Path,help="Reuse an earlier isolated public-resource import, while refreshing current source")
    args=parser.parse_args()
    raise SystemExit(run(args))
