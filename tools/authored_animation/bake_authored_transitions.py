"""Bake only new finite directed transition poses, preserving ANI-05 actions."""
import copy
import json
from bake_directed_performance import ROOT, FIGHTERS, rig, neutral_pose, pose_fields, bake

def main():
    for fid in FIGHTERS:
        folder=ROOT/f"art_source/animation/fighters/{fid}/directed_performance"
        score_path=folder/"transitions_v1.json"
        score=json.loads(score_path.read_text())
        for body in ("male","female"):
            r,_=rig(fid,body)
            ref=json.loads((folder/f"{body}_sole_reference.json").read_text())
            path=ROOT/f"game-godot/data/animation/combat_performance/{fid}_{body}.json"
            doc=json.loads(path.read_text())
            neutral=neutral_pose(r,doc["clips"]["idle_primary"])
            guard=pose_fields(r,neutral,ref)
            for kind,spec in score["transitions"].items():
                load=copy.deepcopy(guard);load.update(spec["load"])
                settle=copy.deepcopy(guard);settle.update(spec["settle"])
                duration=spec["frames"]
                beats=[(0,guard,"guard"),(spec["load_frame"],load,"weight_transfer"),
                       (spec["settle_frame"],settle,"balance_exchange"),(duration,guard,"guard")]
                for facing in (1,-1):
                    name="transition_"+kind+("_left" if facing==-1 else "")
                    template={"duration_frames":duration,"loop":False,"relative_to_rest":False}
                    clip=bake(r,fid,body,ref,neutral,template,beats,name,score_path,facing)
                    clip.update(source_action="ANI06_WIP_"+name,transition_kind=kind,
                                transition_composition="source pelvis/torso/arm deltas over unchanged gait; existing support constraint",
                                transition_mask=["Hips","Spine","Chest","Neck","Head","Shoulder_L","Shoulder_R",
                                  "UpperArm_L","UpperArm_R","LowerArm_L","LowerArm_R","Hand_L","Hand_R"])
                    doc["clips"][name]=clip
            path.write_text(json.dumps(doc,separators=(",",":"))+"\n")
            print("AUTHORED_TRANSITIONS",fid,body,len(score["transitions"])*2,flush=True)
if __name__=="__main__":main()
