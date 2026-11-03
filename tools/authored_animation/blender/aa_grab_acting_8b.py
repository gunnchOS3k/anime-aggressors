"""Opt-in remote saved-action production on the 18 original source rigs.

Writes new source copies, never replaces original .blend/GLB files. Reopens each
saved copy and evaluates it through the established Blender->runtime boundary.
"""
import hashlib
import json
import os
import shutil
import sys
from pathlib import Path

import bpy
from mathutils import Matrix

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/"tools/authored_animation"))
sys.path.insert(0,str(ROOT/"tools/authored_animation/blender"))
from build_grab_acting_8b import make_pack
from aa_directed_performance import digest_source, reference, write_actions, verify_actions, export_runtime


def sha(path):
    h=hashlib.sha256()
    with path.open("rb") as f:
        for part in iter(lambda:f.read(1024*1024),b""):h.update(part)
    return h.hexdigest()


def action_inventory(names=None):
    return {a.name:[(c.data_path,c.array_index,[(list(k.co),k.interpolation) for k in c.keyframe_points])
                    for c in a.fcurves] for a in bpy.data.actions if names is None or a.name in names}


def run():
    assert os.environ.get("GITHUB_ACTIONS")=="true" and sys.platform=="linux", "Remote job only while internal reserve is unmet"
    assert (3,3)<=bpy.app.version[:2]<(4,4), "Pin Blender with the preserved legacy action API; do not silently change action assignment"
    args=sys.argv[sys.argv.index("--")+1:]
    out=Path(args[args.index("--output")+1]).resolve()
    out.mkdir(parents=True,exist_ok=True)
    manifest={"runtime_input_sha":os.environ.get("GITHUB_SHA",""),"rows":[],"human_approved":False,
              "blender_version":bpy.app.version_string,
              "source_install_status":"REMOTE_SAVED_COPIES_NOT_INSTALLED_OVER_ORIGINALS",
              "secondary_deforming_hair_cloth_complete":False,"GLB_exported":False}
    index=json.loads((ROOT/"data/bibles/FIGHTER_BIBLE_INDEX.json").read_text())
    original_bytes=sum((ROOT/f"art_source/collectible_v1/{item['id']}/{body}/candidate.blend").stat().st_size
                       for item in index["fighters"] for body in ("male","female"))
    # Remote copies, action curves and artifact compression. The owner's Mac
    # receives no source binary; its 18GiB guard is never overridden by this job.
    peak_extra=original_bytes*3+1024**3
    remote_free=shutil.disk_usage(out).free
    assert remote_free>peak_extra+1024**3,"Insufficient ephemeral runner capacity"
    manifest["storage"]={"remote_free_bytes":remote_free,"anticipated_peak_extra_bytes":peak_extra,
                         "owner_internal_binary_allocation_bytes":0,"owner_reserve_bypassed":False}
    for item in index["fighters"]:
        fid=item["id"]
        for body in ("male","female"):
            source=ROOT/f"art_source/collectible_v1/{fid}/{body}/candidate.blend"
            before_hash=sha(source)
            bpy.ops.wm.open_mainfile(filepath=str(source))
            arm=next(o for o in bpy.data.objects if o.type=="ARMATURE")
            geometry=digest_source(arm)
            old=action_inventory();names=set(old)
            tracks=[t.mute for t in arm.animation_data.nla_tracks]
            old_action=arm.animation_data.action;old_frame=bpy.context.scene.frame_current
            doc=make_pack(fid,body,reference(arm,fid,body))
            actions=write_actions(arm,fid,body,doc)
            pre=verify_actions(arm,fid,body,doc)
            assert pre["PASS"],pre
            assert old==action_inventory(names),"Original actions changed"
            assert geometry==digest_source(arm),"Original geometry/rest/weights changed"
            arm.animation_data.action=old_action
            for track,mute in zip(arm.animation_data.nla_tracks,tracks):track.mute=mute
            bpy.context.scene.frame_set(old_frame)
            for bone in arm.pose.bones:bone.matrix_basis=Matrix.Identity(4)
            target=out/f"saved_sources/{fid}/{body}/candidate_8b.blend"
            target.parent.mkdir(parents=True,exist_ok=True)
            bpy.context.preferences.filepaths.save_version=0
            bpy.ops.wm.save_as_mainfile(filepath=str(target))
            saved_hash=sha(target)
            # A memory-only action pass is never a saved-source pass.
            bpy.ops.wm.open_mainfile(filepath=str(target))
            arm=next(o for o in bpy.data.objects if o.type=="ARMATURE")
            assert geometry==digest_source(arm) and old==action_inventory(names)
            doc=export_runtime(arm,fid,body,doc)
            verified=verify_actions(arm,fid,body,doc)
            assert verified["PASS"],verified
            for clip in doc["clips"].values():
                clip["source_blend"]=str(target.relative_to(out))
                clip["source_blend_sha256"]=saved_hash
                clip["original_source_blend"]=str(source.relative_to(ROOT))
            doc.update(source_actions_saved=True,source_runtime_verified=True,
                       status="SAVED_ORIGINAL_ACTION_WIP_NATIVE_AND_HUMAN_PENDING",
                       source_base_blend_sha256=before_hash,source_saved_blend_sha256=saved_hash,
                       remote_run_id=os.environ.get("GITHUB_RUN_ID",""))
            output=out/f"runtime/game-godot/data/animation/grab_acting_8b/{fid}_{body}.json"
            output.parent.mkdir(parents=True,exist_ok=True)
            output.write_text(json.dumps(doc,separators=(",",":"))+"\n")
            assert sha(source)==before_hash,"Original source copy overwritten"
            row={"fighter":fid,"body":body,"original_source":str(source.relative_to(ROOT)),
                 "original_source_sha256":before_hash,"saved_source":str(target.relative_to(out)),
                 "saved_source_sha256":saved_hash,"source_geometry_rest_weights_sha256":geometry,
                 "original_actions_preserved":len(names),"new_saved_actions":actions,
                 "rig_bones":[b.name for b in arm.data.bones],"source_runtime_verification":verified,
                 "runtime_file":str(output.relative_to(out)),"runtime_sha256":sha(output),
                 "human_approved":False,"native_visual_verified":False}
            manifest["rows"].append(row)
            (out/"runtime/PRODUCTION_MANIFEST.json").write_text(json.dumps(manifest,indent=2)+"\n")
            print("SAVED_8B",fid,body,len(actions),verified,flush=True)
    assert len(manifest["rows"])==18
    manifest["complete"]=True
    (out/"runtime/PRODUCTION_MANIFEST.json").write_text(json.dumps(manifest,indent=2)+"\n")


if __name__=="__main__":run()
