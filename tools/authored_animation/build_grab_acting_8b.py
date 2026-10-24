"""Finite original 8B poses -> rig-specific keys. This is not a saved-action pass.

Only the Blender saved/reopened action boundary may promote these keys to an
installable runtime overlay. No geometry, gameplay data or runtime IK is authored.
"""
import copy
import json
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/authored_animation"))
from bake_directed_performance import bake, neutral_pose, pose_fields

SCORE = ROOT / "art_source/animation/grab_acting_8b/score_v1.json"


def make_pack(fid, body, reference):
    from bake_directed_performance import rig, fk
    r, model_hash = rig(fid, body)
    baseline = json.loads((ROOT / f"game-godot/data/animation/combat_choreography/{fid}_{body}.json").read_text())
    spec = json.loads(SCORE.read_text())["fighters"][fid]
    neutral = neutral_pose(r, baseline["clips"]["idle_primary"])
    guard = pose_fields(r, neutral, reference)
    height = float(fk(r, {}, {})["Head"][1][1])
    poses = {"guard": guard}
    for name, fields in spec["poses"].items():
        pose = copy.deepcopy(guard)
        for field, value in fields.items():
            if field in ("pelvis", "R", "L"):
                pose[field] = list(np.array(guard[field]) + np.array(value) * height)
            elif field in ("front", "back"):
                pose[field] = list(np.array(value) * height)
            else:
                pose[field] = value
        poses[name] = pose
    # Every beat refers to that fighter's own authored regional poses. The shared
    # bake solves unmodified segment lengths on each actual body rig.
    clips = {}

    def add(name, beats, template=None, loop=False):
        base = copy.deepcopy(template or {})
        base.update(duration_frames=beats[-1][0], loop=loop, relative_to_rest=False)
        for facing in (1, -1):
            key = name + ("_left" if facing == -1 else "")
            clip = bake(r, fid, body, reference, neutral, base,
                        [(frame, poses[pose], label) for frame, pose, label in beats], key, SCORE, facing)
            clip.update(source_action="ANI08B_WIP_" + key, source_blend="PENDING_SAVED_ACTION",
                        acting_category="8B_original_grab_acting", human_approved=False)
            clips[key] = clip

    tempo = spec["tempo"]
    hold = int(tempo["hold_frames"])
    for name, pose, secondary in (("grab_hold_attacker", "hold", "hold_load"),
                                  ("grab_hold_victim", "restrained", "resist")):
        add(name, [(0, pose, "supported_hold"), (hold//2, secondary, "contained_weight_exchange"),
                   (hold, pose, "loop_seam")], loop=True)
    total = int(tempo["escape_frames"])
    add("grab_escape", [(0, "restrained", "restraint"), (max(1,total//3), "escape", "break_grip"),
                        (total*2//3, "recover", "support_catch"), (total, "guard", "guard")])
    total = int(tempo["recovery_frames"])
    add("grab_recovery", [(0,"hold","released_grip"),(total//2,"recover","support_exchange"),(total,"guard","guard")])
    add("grab_whiff", [(0,"acquire","miss"),(total//2,"whiff","checked_momentum"),(total,"guard","guard")])
    grab = baseline["clips"]["grab"]
    contact = int(grab["contact_frame"]); total = int(grab["duration_frames"])
    add("grab", [(0,"guard","guard"),(max(1,contact//2),"acquire_load","anticipation"),
                 (contact,"acquire","grip_region"),(total,"guard","guard")], grab)
    for direction in ("forward","back","up","down"):
        template = baseline["clips"]["throw_"+direction]
        total = int(template["duration_frames"])
        add("throw_"+direction, [(0,"hold","release_at_gameplay_frame_zero"),
            (max(2,int(template["startup_frames"])),"release_"+direction,"follow_through"),
            (max(3,total-3),"recover","support_replant"),(total,"guard","guard")], template)
        total = int(tempo["air_frames"])
        add("throw_reaction_"+direction, [(0,"restrained","confirmed_release"),
            (max(1,total//4),"air_"+direction,"directional_recoil"),
            (total,"air_"+direction,"airborne_terminal_hold")])
    total = int(tempo["landing_frames"])
    add("throw_landing", [(0,"landing","real_floor_contact"),(max(1,total//4),"landing","absorb"),
                           (total*2//3,"recover","support_replant"),(total,"guard","guard")])
    return {"schema":"original_grab_acting_8b.v1","fighter_id":fid,"body_variant":body,
            "source_model_sha256":model_hash,"source_score":str(SCORE.relative_to(ROOT)),
            "source_actions_saved":False,"source_runtime_verified":False,
            "status":"UNSAVED_POSE_CANDIDATE_NOT_RUNTIME_AUTHORITY","human_approved":False,
            "source_bible":spec["bible"],"intent":spec["intent"],"clips":clips}


def inspect_all():
    # Read-only original sole measurements. They are not promoted to newly saved
    # source or art acceptance by this small deterministic support check.
    refs = json.loads((ROOT/"artifacts/v1_closure/parity_foundation/rig_controls_in_memory.json").read_text())["rows"]
    rows = []
    for row in refs:
        ref = {"soles":{}}
        for side, sole in row["sole_references"].items():
            x,y,z = sole["sole_rig_blender_m"]
            ref["soles"][side] = {"world_rest_m":[x,z,-y],"foot_local_m":sole["foot_local_m"]}
        doc = make_pack(row["fighter"],row["body"],ref)
        rows.append({"fighter":row["fighter"],"body":row["body"],"clips":len(doc["clips"]),
                     "largest_hand_constraint_residual_m":max(c["max_hand_target_clamp_m"] for c in doc["clips"].values()),
                     "source_actions_saved":False})
    print(json.dumps({"rows":rows,"scope":"Finite pose baking only; no Blender save or acting acceptance"},indent=2))


if __name__ == "__main__":
    inspect_all()
