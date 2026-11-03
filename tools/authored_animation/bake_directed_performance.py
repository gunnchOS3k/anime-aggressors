"""Bake the hand-directed source score onto four existing rigs, without exports.

The finite source beats are the animation authority. The existing offline arm
and leg constraints preserve anatomy/support between beats. This is WIP acting,
never an automated human-quality judgement or a new runtime geometry solver.
"""
import copy
import json
import math
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/v1_closure"))
from build_combat_choreography import rig, fk, solve, euler, quat, matrix, smooth

FIGHTERS = ("kaia-windrow", "juno-spark")


def neutral_pose(r, clip):
    rotations, positions = {}, {}
    for n in r:
        key = clip["bone_tracks"].get(n, [{"rotation_quat": quat(r[n]["r"])}])[0]
        rotations[n] = matrix(key["rotation_quat"])
        positions[n] = np.array(key.get("position_m", r[n]["p"]))
    return fk(r, rotations, positions), rotations, positions


def pose_fields(r, neutral, ref):
    g, _, _ = neutral
    return {"pelvis": list(g["Hips"][1] - fk(r, {}, {})["Hips"][1]),
            "hips": [0, 0, 0], "spine": [-.286, 0, 0], "chest": [-1.146, 0, 0],
            "neck": [-.172, 0, 0], "head": [.252, 0, 0],
            "R": list(g["Hand_R"][1]), "L": list(g["Hand_L"][1]),
            "front": [0, 0, 0], "back": [0, 0, 0], "front_roll": 0,
            "wrist_R": [0, 0, 0], "wrist_L": [0, 0, 0], "shoulder": 0}


def directed(spec, key, base):
    result = copy.deepcopy(base)
    result.update(spec[key])
    if key in ("contact", "follow"):
        result["wrist_R"] = [-55, 12 if spec["fighter"] == "kaia-windrow" else 0, -6]
        result["shoulder"] = 7 if spec["fighter"] == "kaia-windrow" else 4
    if key == "return":
        result["front_roll"] = 7
        result["wrist_R"] = [-20, 0, 0]
    return result


def interpolate(a, b, t):
    return {n: np.array(a[n]) * (1-t) + np.array(b[n]) * t for n in a}


def mirrored(pose):
    result = {n: np.array(v).copy() for n, v in pose.items()}
    for n in ("pelvis", "front", "back"):
        result[n][0] *= -1
    for n in ("hips", "spine", "chest", "neck", "head"):
        result[n][1:] *= -1
    for a, b in (("R", "L"), ("wrist_R", "wrist_L")):
        result[a], result[b] = result[b].copy(), result[a].copy()
        if a == "R":
            result[a][0] *= -1; result[b][0] *= -1
        else:
            result[a][1:] *= -1; result[b][1:] *= -1
    result["shoulder"] *= -1
    return result


def bake(r, fid, body, ref, neutral, template, beats, name, score_path, facing=1):
    clip = copy.deepcopy(template)
    total = int(clip["duration_frames"])
    rest = fk(r, {}, {})
    output = {n: [] for n in r if n != "Root"}
    max_slip = 0.; reach_clamp = 0.
    for frame in range(total+1):
        a, b = beats[0], beats[-1]
        for left, right in zip(beats, beats[1:]):
            if left[0] <= frame <= right[0]:
                a, b = left, right; break
        u = smooth(max(0, min(1, (frame-a[0])/max(1, b[0]-a[0]))))
        p = interpolate(a[1], b[1], u)
        if name in ("walk_loop","run_loop","dash_loop"):
            # Preserve the established distance-driven linear stance curve.
            # Only the keyed swing has easing; easing a planted foot would
            # visibly skate against the unchanged simulation displacement.
            phase = frame/max(1,total)
            stride = float(template["gait_half_stride_m"])
            if phase <= .5:
                p["back"][1] = 0
                p["back"][2] = stride*(1-4*phase)
            else:
                p["front"][1] = 0
                p["front"][2] = stride*(3-4*phase)
        if facing == -1: p = mirrored(p)
        rots = {}
        pos = {"Hips": r["Hips"]["p"] + p["pelvis"]}
        for n, field in (("Hips", "hips"), ("Spine", "spine"), ("Chest", "chest"), ("Neck", "neck"), ("Head", "head")):
            rots[n] = r[n]["r"] @ euler(*np.radians(p[field]))
        for side, sign in (("L", -1), ("R", 1)):
            rots["Shoulder_"+side] = r["Shoulder_"+side]["r"] @ euler(0, math.radians(float(p["shoulder"]))*sign, 0)
            target = p[side]
            g = solve(r, rots, pos, "UpperArm_"+side, "LowerArm_"+side, "Hand_"+side,
                      target, np.array([sign*.7, -.5, -.12]))
            reach_clamp = max(reach_clamp, float(np.linalg.norm(g["Hand_"+side][1]-target)))
            desired = euler(*np.radians(p["wrist_"+side])) @ rest["Hand_"+side][0]
            rots["Hand_"+side] = g[r["Hand_"+side]["parent"]][0].T @ desired
        front = "R" if facing == 1 else "L"
        for side in ("L", "R"):
            foot = "Foot_" + side
            offset = p["front"] if side == front else p["back"]
            roll = float(p["front_roll"]) if side == front else 0.
            rotation = euler(math.radians(roll), 0, 0) @ rest[foot][0]
            anchor = np.array(ref["soles"][side]["world_rest_m"]) + offset
            local = np.array(ref["soles"][side]["foot_local_m"])
            assert np.linalg.norm(rest[foot][1]+rest[foot][0]@local-np.array(ref["soles"][side]["world_rest_m"])) < 1e-4
            goal = anchor - rotation @ local
            # Author the live +Z knee plane into the actual source keys. The
            # legacy runtime knee correction remains available for old clips.
            g = solve(r, rots, pos, "UpperLeg_"+side, "LowerLeg_"+side, foot, goal, np.array([0, 0, 1.]))
            rots[foot] = g[r[foot]["parent"]][0].T @ rotation
            # Articulated toe return, no stretch or length changes.
            toe = "Toes_" + side
            rots[toe] = r[toe]["r"] @ euler(math.radians(-roll*.6), 0, 0)
            if side != front and not np.any(p["back"]):
                point = g[foot][1] + rotation @ local
                max_slip = max(max_slip, float(np.linalg.norm(point-anchor)))
        # Exact inherited guard boundaries keep cancel/neutral continuity.
        if frame == 0 and beats[0][2] == "guard" or frame == total and beats[-1][2] == "guard":
            rots, pos = neutral[1], neutral[2]
        for n in output:
            key = {"time_s": round(frame/60, 6), "rotation_quat": [round(float(x), 7) for x in quat(rots.get(n, r[n]["r"]))]}
            if n == "Hips": key["position_m"] = [round(float(x), 7) for x in pos["Hips"]]
            output[n].append(key)
    clip.update(bone_tracks=output, directed_source=str(score_path.relative_to(ROOT)),
                directed_beats={label: frame for frame, _, label in beats},
                authoring="Original directed WIP keyposes on preserved rig; offline support constraints; not human approved",
                max_baked_support_slip_m=max_slip, max_hand_target_clamp_m=reach_clamp,
                sole_reference=f"art_source/animation/fighters/{fid}/directed_performance/{body}_sole_reference.json",
                root_motion_authoritative=False, human_approved=False,
                posture_authority="source_clip")
    if "support_foot" in clip:
        clip["support_foot"] = "L" if facing == 1 else "R"
    if "striking_limb" in clip:
        clip["striking_limb"] = "Hand_R" if facing == 1 else "Hand_L"
    return clip


def main():
    for fid in FIGHTERS:
        directory = ROOT / f"art_source/animation/fighters/{fid}/directed_performance"
        score_path = directory / "score_v1.json"
        spec = json.loads(score_path.read_text()); spec["fighter"] = fid
        for body in ("male", "female"):
            r, h = rig(fid, body)
            ref = json.loads((directory / (body+"_sole_reference.json")).read_text())
            base_path = ROOT / f"game-godot/data/animation/combat_choreography/{fid}_{body}.json"
            performance_path = ROOT / f"game-godot/data/animation/combat_performance/{fid}_{body}.json"
            base = json.loads(base_path.read_text()); performance = json.loads(performance_path.read_text())
            # Legacy clips must reset newly articulated toes on every transition.
            for doc in (base, performance):
                for clip in doc["clips"].values():
                    for toe in ("Toes_L", "Toes_R"):
                        if toe not in clip["bone_tracks"]:
                            clip["bone_tracks"][toe] = [{"time_s": round(f/60,6), "rotation_quat": [float(x) for x in quat(r[toe]["r"])]} for f in range(clip["duration_frames"]+1)]
            neutral = neutral_pose(r, base["clips"]["idle_primary"])
            guard = pose_fields(r, neutral, ref)
            poses = {n: directed(spec, n, guard) for n in ("load", "contact", "follow", "return", "hurt", "land", "jump", "charge", "heavy_anticipation", "heavy_contact", "heavy_follow", "poised", "shield", "projectile_contact", "grip", "throw_forward", "throw_back", "throw_up", "throw_down", "defeated", "gait_contact", "gait_pass")}
            new = {}
            for mid in ("jab_1", "heavy_attack", "side_special", "neutral_special_projectile"):
                template = base["clips"][mid]
                s = template["startup_frames"]; a = template["active_frames"]; total = template["duration_frames"]
                load = max(1, round(s*.55)); contact = int(template["contact_frame"])
                release = min(total-3, s+a+2); settle = min(total-1, release+max(1, round((total-release)*.5)))
                preparation = poses["heavy_anticipation"] if mid == "heavy_attack" else poses["charge"] if mid == "neutral_special_projectile" else poses["load"]
                extension = poses["heavy_contact"] if mid == "heavy_attack" else poses["projectile_contact"] if mid == "neutral_special_projectile" else poses["contact"]
                follow = poses["heavy_follow"] if mid == "heavy_attack" else poses["projectile_contact"] if mid == "neutral_special_projectile" else poses["follow"]
                beats = [(0, guard, "guard"), (load, preparation, "anticipation"), (contact, extension, "contact"), (release, follow, "follow_through"), (settle, poses["return"], "recovery_step"), (total, guard, "guard")]
                for facing in (1, -1):
                    name = mid + ("_left" if facing == -1 else "")
                    new[name] = bake(r, fid, body, ref, neutral, template, beats, name, score_path, facing)
                    # The blocking and selected runtime overlay share source,
                    # active poses and unchanged frame metadata.
                    base["clips"][name] = copy.deepcopy(new[name])
            for mid in ("grab", "throw_forward", "throw_back", "throw_up", "throw_down"):
                template = base["clips"][mid]; total = template["duration_frames"]
                if mid == "grab":
                    contact = int(template["contact_frame"])
                    beats = [(0, guard, "guard"), (max(1,contact//2), poses["load"], "reach"), (contact, poses["grip"], "grip"), (total, guard, "guard")]
                else:
                    # Throw damage/release is already authoritative at frame0.
                    # Its preparation is the preceding real grabbed hold.
                    beats = [(0, poses["grip"], "release"), (max(2,int(template["startup_frames"])), poses[mid], "follow_through"), (total-3, poses["return"], "replant"), (total, guard, "guard")]
                for facing in (1,-1):
                    name=mid+("_left" if facing==-1 else "")
                    new[name]=bake(r,fid,body,ref,neutral,template,beats,name,score_path,facing)
                    base["clips"][name]=copy.deepcopy(new[name])
            states = {
                "idle_primary": [(0, guard, "guard"), (16 if fid == "juno-spark" else 30, poses["poised"], "ready_shift"), (36 if fid == "juno-spark" else 45, guard, "reset"), (60, guard, "guard")],
                "shield_hold": [(0, poses["shield"], "brace"), (20, poses["shield"], "hold"), (40, poses["shield"], "brace")],
                "aura_charge": [(0, guard, "guard"), (15, poses["charge"], "gather"), (45, poses["charge"], "contain"), (60, guard, "guard")],
                "jump": [(0, guard, "guard"), (6, poses["jump"], "takeoff"), (18, poses["jump"], "air_hold"), (24, guard, "guard")],
                "land_soft": [(0, poses["land"], "catch"), (5, poses["land"], "support"), (14, poses["return"], "stabilize"), (24, guard, "guard")],
                "land_hard": [(0, poses["land"], "catch"), (6, poses["land"], "support"), (16, poses["return"], "stabilize"), (30, guard, "guard")],
                "reaction_light": [(0, poses["hurt"], "impact"), (3, poses["hurt"], "recoil"), (10, poses["return"], "catch_balance"), (18, guard, "guard")],
                "reaction_heavy": [(0, poses["hurt"], "impact"), (5, poses["hurt"], "recoil"), (19, poses["land"], "catch_balance"), (30, guard, "guard")],
                "reaction_elemental": [(0, poses["hurt"], "impact"), (5, poses["hurt"], "recoil"), (19, poses["land"], "catch_balance"), (30, guard, "guard")],
                "ko": [(0,poses["hurt"],"loss_of_balance"),(12,poses["land"],"fold"),(36,poses["defeated"],"terminal_hold")],
                "defeat": [(0,poses["hurt"],"loss_of_balance"),(16,poses["land"],"fold"),(48,poses["defeated"],"terminal_hold")],
            }
            for gait in ("walk_loop","run_loop","dash_loop"):
                template=base["clips"][gait];total=template["duration_frames"]
                contact=copy.deepcopy(poses["gait_contact"]);passing=copy.deepcopy(poses["gait_pass"])
                # Retain established phase ownership: left support first,
                # then right support. The swing/stance audit stays unchanged.
                # Retain the existing distance-driven cycle length/stride.
                stride=float(template["gait_half_stride_m"])
                contact["front"][2]=-stride;contact["back"][2]=stride
                opposite=copy.deepcopy(contact);opposite["front"],opposite["back"]=opposite["back"],opposite["front"]
                other_pass=copy.deepcopy(passing);other_pass["front"],other_pass["back"]=other_pass["back"],other_pass["front"]
                beats=[(0,contact,"left_contact"),(total//4,passing,"right_swing"),(total//2,opposite,"right_contact"),(total*3//4,other_pass,"left_swing"),(total,contact,"loop_seam")]
                new[gait]=bake(r,fid,body,ref,neutral,template,beats,gait,score_path)
                base["clips"][gait]=copy.deepcopy(new[gait])
            for name, beats in states.items():
                template = copy.deepcopy(base["clips"].get(name, performance["clips"].get(name, {})))
                template.update(duration_frames=beats[-1][0], loop=name in ("idle_primary", "shield_hold", "aura_charge"), relative_to_rest=False)
                new[name] = bake(r, fid, body, ref, neutral, template, beats, name, score_path)
                if name in base["clips"]: base["clips"][name] = copy.deepcopy(new[name])
            performance["clips"].update(new)
            performance["directed_source_status"] = "AUTHORED_WIP_VISUAL_VERIFICATION_PENDING"
            performance["source_sole_reference"] = ref
            for path, doc in ((base_path, base), (performance_path, performance)):
                path.write_text(json.dumps(doc, separators=(",", ":"))+"\n")
            print("DIRECTED_BAKE", fid, body, len(new), flush=True)


if __name__ == "__main__":
    main()
