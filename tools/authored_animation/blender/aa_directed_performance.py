"""Edit actions on the preserved collectible rigs; never rebuild/export models.

The source score is a finite set of directed poses. Existing offline two-bone
constraints only bake those poses onto the actual rig. No runtime solver,
stretch, root motion, gameplay edits, generated mesh, rendering or GLB export.
"""
import hashlib
import json
import sys
from pathlib import Path

import bpy
from mathutils import Matrix

ROOT = Path(__file__).resolve().parents[3]
C = Matrix(((1, 0, 0, 0), (0, 0, 1, 0), (0, -1, 0, 0), (0, 0, 0, 1)))
FIGHTERS = ("kaia-windrow", "juno-spark")


def digest_source(arm):
    """Geometry, weights, rest skeleton and object transforms must be immutable."""
    meshes = {}
    for ob in bpy.data.objects:
        if ob.type != "MESH":
            continue
        meshes[ob.name] = {
            "vertices": [list(v.co) for v in ob.data.vertices],
            "weights": [[(g.group, g.weight) for g in v.groups] for v in ob.data.vertices],
            "groups": [g.name for g in ob.vertex_groups],
            "transform": [list(row) for row in ob.matrix_local],
        }
    bones = {b.name: [list(row) for row in b.matrix_local] for b in arm.data.bones}
    return hashlib.sha256(json.dumps({"meshes": meshes, "bones": bones}, sort_keys=True).encode()).hexdigest()


def reference(arm, fid, body):
    result = {"fighter": fid, "body": body, "space": "Godot rig metres; +Y up, +Z live forward",
              "source_digest": digest_source(arm), "human_approved": False, "soles": {}}
    for side in ("L", "R"):
        ob = bpy.data.objects.get("Boot " + side)
        assert ob is not None and ob.vertex_groups[0].name == "Foot_" + side
        verts = [arm.matrix_world.inverted() @ ob.matrix_world @ v.co for v in ob.data.vertices]
        bottom = min(v.z for v in verts)
        points = [v for v in verts if abs(v.z - bottom) < 1e-5]
        sole = sum(points, points[0] * 0) / len(points)
        bone = arm.data.bones["Foot_" + side]
        local = bone.matrix_local.inverted() @ sole
        result["soles"][side] = {"world_rest_m": list(C @ sole), "foot_local_m": list(local),
                                  "basis": "bottom vertices of original weighted Boot mesh; not ankle joint"}
    result["hair_binding"] = "Existing Head-bound meshes preserved; independent hair weights/controls still required."
    return result


def original_actions_digest():
    curves = {a.name: [(f.data_path, f.array_index,
                       [(list(k.co), k.interpolation) for k in f.keyframe_points])
                      for f in a.fcurves]
              for a in bpy.data.actions if not a.name.startswith("ANI05_WIP_")}
    return hashlib.sha256(json.dumps(curves, sort_keys=True).encode()).hexdigest()


def transform(global_pose):
    r, p = global_pose
    m = Matrix.Identity(4)
    for i in range(3):
        for j in range(3):
            m[i][j] = float(r[i][j])
        m[i][3] = float(p[i])
    return C.inverted() @ m


def verify_actions(arm, fid, body, doc):
    """Evaluate saved Blender actions against the actual runtime pose data."""
    sys.path.insert(0, str(ROOT / "tools/v1_closure"))
    from build_combat_choreography import rig, fk, matrix
    import numpy as np
    skeleton, _ = rig(fid, body)
    for track in arm.animation_data.nla_tracks:
        track.mute = True
    maximum = 0.; samples = 0
    for name, clip in doc["clips"].items():
        if not clip.get("directed_source"):
            continue
        action = bpy.data.actions["ANI05_WIP_"+name]
        arm.animation_data.action = action
        for frame in range(clip["duration_frames"]+1):
            bpy.context.scene.frame_set(frame)
            bpy.context.view_layer.update()
            rots, positions = {}, {}
            for bone, keys in clip["bone_tracks"].items():
                key = keys[frame]
                rots[bone] = matrix(key["rotation_quat"])
                if "position_m" in key: positions[bone] = np.array(key["position_m"])
            expected = fk(skeleton, rots, positions)
            for bone in arm.pose.bones:
                target = transform(expected[bone.name])
                maximum = max(maximum, max(abs(bone.matrix[i][j]-target[i][j]) for i in range(4) for j in range(4)))
            samples += 1
    return {"PASS": maximum < .0002, "max_matrix_component_error": maximum,
            "frames_evaluated": samples, "scope": "saved Blender evaluated pose versus rig-specific runtime keys, not visual quality"}


def write_actions(arm, fid, body, doc):
    # Import only our source clips. All original actions and NLA strips survive.
    sys.path.insert(0, str(ROOT / "tools/v1_closure"))
    from build_combat_choreography import rig, fk, matrix
    import numpy as np

    skeleton, _ = rig(fid, body)
    rest = fk(skeleton, {}, {})
    for name in skeleton:
        expected = transform(rest[name])
        assert max(abs(expected[i][j] - arm.data.bones[name].matrix_local[i][j])
                   for i in range(4) for j in range(4)) < 2e-4, name
    for track in arm.animation_data.nla_tracks:
        track.mute = True
    original_action = arm.animation_data.action
    written = []
    for clip_name, clip in doc["clips"].items():
        if not clip.get("directed_source"):
            continue
        name = "ANI05_WIP_" + clip_name
        action = bpy.data.actions.get(name)
        if action is not None:
            assert "--refresh-owned" in sys.argv and action.get("source_score") == clip["directed_source"], "Preserve existing action; use a new version: " + name
            assert action.get("status") == "AUTHORED_WIP_NOT_HUMAN_APPROVED"
            # Only this increment's unaccepted WIP curves can be refreshed.
            # All original 147 actions/strips are independently hash-protected.
            for curve in list(action.fcurves): action.fcurves.remove(curve)
            for marker in list(action.pose_markers): action.pose_markers.remove(marker)
        else:
            action = bpy.data.actions.new(name)
        action.use_fake_user = True
        action["status"] = "AUTHORED_WIP_NOT_HUMAN_APPROVED"
        action["source_score"] = clip["directed_source"]
        action["combat_authority_unchanged"] = True
        arm.animation_data.action = action
        frames = sorted(set(int(round(k["time_s"] * 60)) for k in clip["bone_tracks"]["Hips"]))
        for frame in frames:
            rots, positions = {}, {}
            for bone, keys in clip["bone_tracks"].items():
                key = min(keys, key=lambda k: abs(k["time_s"] * 60 - frame))
                rots[bone] = matrix(key["rotation_quat"])
                if "position_m" in key:
                    positions[bone] = np.array(key["position_m"])
            global_pose = fk(skeleton, rots, positions)
            for bone in arm.pose.bones:
                # Preserve compatibility with the original Euler-keyed actions.
                assert bone.rotation_mode == "XYZ", bone.name
                # Compute local basis from desired parent pose explicitly.
                # Assigning pose.matrix recursively uses stale evaluated parent
                # matrices until a depsgraph update, corrupting the saved keys.
                rest = arm.data.bones[bone.name].matrix_local
                chain = rest
                if bone.parent is not None:
                    parent = bone.parent.name
                    chain = transform(global_pose[parent]) @ arm.data.bones[parent].matrix_local.inverted() @ rest
                bone.matrix_basis = chain.inverted() @ transform(global_pose[bone.name])
                bone.keyframe_insert("rotation_euler", frame=frame, group=bone.name)
                bone.keyframe_insert("location", frame=frame, group=bone.name)
                # Bone scale is never an animation channel in this increment.
        for curve in action.fcurves:
            for key in curve.keyframe_points:
                key.interpolation = "LINEAR"
        for beat, frame in clip.get("directed_beats", {}).items():
            marker = action.pose_markers.new(beat)
            marker.frame = frame
        written.append(name)
    arm.animation_data.action = original_action
    # Restore original strip mute states, set by the caller.
    return written


def main():
    inspect = "--inspect-only" in sys.argv
    verify = "--verify-only" in sys.argv
    for fid in FIGHTERS:
        for body in ("male", "female"):
            source = ROOT / f"art_source/collectible_v1/{fid}/{body}/candidate.blend"
            bpy.ops.wm.open_mainfile(filepath=str(source))
            arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
            before = digest_source(arm)
            old_actions = original_actions_digest()
            ref = reference(arm, fid, body)
            target = ROOT / f"art_source/animation/fighters/{fid}/directed_performance/{body}_sole_reference.json"
            target.parent.mkdir(parents=True, exist_ok=True)
            if inspect:
                target.write_text(json.dumps(ref, indent=2) + "\n")
                print("SOLE_REFERENCE", fid, body, flush=True)
                continue
            if verify:
                doc = json.loads((ROOT / f"game-godot/data/animation/combat_performance/{fid}_{body}.json").read_text())
                result = verify_actions(arm, fid, body, doc)
                (target.parent / (body+"_evaluated_actions.json")).write_text(json.dumps(result, indent=2)+"\n")
                print("DIRECTED_VERIFY", fid, body, result, flush=True)
                assert result["PASS"], "Source action differs from runtime keys"
                continue
            assert json.loads(target.read_text())["source_digest"] == before
            muted = [t.mute for t in arm.animation_data.nla_tracks]
            original_action = arm.animation_data.action
            original_frame = bpy.context.scene.frame_current
            doc = json.loads((ROOT / f"game-godot/data/animation/combat_performance/{fid}_{body}.json").read_text())
            actions = write_actions(arm, fid, body, doc)
            verified = verify_actions(arm, fid, body, doc)
            assert verified["PASS"], verified
            (target.parent / (body+"_evaluated_actions.json")).write_text(json.dumps(verified, indent=2)+"\n")
            arm.animation_data.action = original_action
            for track, value in zip(arm.animation_data.nla_tracks, muted):
                track.mute = value
            bpy.context.scene.frame_set(original_frame)
            # Restore rest/edit view; do not save a visibly deformed model.
            for bone in arm.pose.bones:
                bone.matrix_basis = Matrix.Identity(4)
            for side in ("L", "R"):
                marker = bpy.data.objects.new("SoleContact_" + side, None)
                marker.empty_display_type = "PLAIN_AXES"
                marker.empty_display_size = .025
                marker["non_deforming_source_control"] = True
                bpy.context.collection.objects.link(marker)
                marker.parent = arm
                marker.parent_type = "BONE"
                marker.parent_bone = "Foot_" + side
                bpy.context.view_layer.update()
                point = ref["soles"][side]["world_rest_m"]
                from mathutils import Vector
                marker.matrix_world.translation = C.inverted() @ Vector(point)
            assert digest_source(arm) == before, "Geometry/rest/weights changed"
            assert original_actions_digest() == old_actions, "Original action changed"
            # Git already preserves the original binary. Avoid automatic .blend1
            # duplication without deleting or touching any existing backups.
            bpy.context.preferences.filepaths.save_version = 0
            bpy.ops.wm.save_as_mainfile(filepath=str(source))
            report = {"source": str(source.relative_to(ROOT)), "source_digest_before": before,
                      "source_digest_after": digest_source(arm), "actions": actions,
                      "meshes_rest_weights_unchanged": True, "GLB_exported": False,
                      "original_actions_preserved": True, "original_actions_sha256": old_actions,
                      "VISUAL_VERIFICATION_PENDING": True, "human_approved": False}
            (target.parent / (body + "_source_actions.json")).write_text(json.dumps(report, indent=2) + "\n")
            print("DIRECTED_SOURCE_SAVED", fid, body, len(actions), flush=True)


if __name__ == "__main__":
    main()
