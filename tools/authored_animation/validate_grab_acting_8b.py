"""Check complete saved/reopened source receipts. No final-art approval inference."""
import hashlib
import json
import math
import sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]


def digest(path):
    h=hashlib.sha256()
    with path.open("rb") as f:
        for part in iter(lambda:f.read(1024*1024),b""):h.update(part)
    return h.hexdigest()


def validate(folder, require_sources=True):
    data=json.loads((folder/"runtime/PRODUCTION_MANIFEST.json").read_text())
    assert data.get("complete") is True and data.get("human_approved") is False
    fighters=json.loads((ROOT/"data/bibles/FIGHTER_BIBLE_INDEX.json").read_text())["fighters"]
    expected={(f["id"],body) for f in fighters for body in ("male","female")}
    assert len(data["rows"])==18 and {(r["fighter"],r["body"]) for r in data["rows"]}==expected
    required={"grab","grab_whiff","grab_hold_attacker","grab_hold_victim","grab_escape","grab_recovery","throw_landing"}
    required|={"throw_"+d for d in ("forward","back","up","down")}
    required|={"throw_reaction_"+d for d in ("forward","back","up","down")}
    required|={c+"_left" for c in list(required)}
    for row in data["rows"]:
        p=folder/row["runtime_file"]
        assert digest(p)==row["runtime_sha256"]
        doc=json.loads(p.read_text())
        assert doc.get("schema")=="original_grab_acting_8b.v1"
        assert doc.get("source_actions_saved") is True and doc.get("source_runtime_verified") is True
        assert doc["source_base_blend_sha256"]==row["original_source_sha256"]
        assert doc["source_saved_blend_sha256"]==row["saved_source_sha256"]
        assert doc["fighter_id"]==row["fighter"] and doc["body_variant"]==row["body"]
        assert doc["human_approved"] is False and row["native_visual_verified"] is False
        assert row["source_runtime_verification"]["PASS"] is True
        assert set(doc["clips"])==required
        assert set(row["new_saved_actions"])=={c["source_action"] for c in doc["clips"].values()}
        assert len(row["rig_bones"])==22 and row["original_actions_preserved"]>=147
        assert len(set(row["rig_bones"]))==22
        assert row["source_runtime_verification"]["frames_evaluated"]==sum(c["duration_frames"]+1 for c in doc["clips"].values())
        assert row["source_runtime_verification"]["max_matrix_component_error"]<.0002
        for name,clip in doc["clips"].items():
            assert clip["source_blend_sha256"]==row["saved_source_sha256"]
            assert clip["source_action"]=="ANI08B_WIP_"+name
            assert clip["source_blend"]==row["saved_source"]
            # The established bake intentionally keeps Root static: 21 keyed
            # pose bones + the preserved unanimated Root make the 22-bone rig.
            assert "Root" in row["rig_bones"]
            assert set(clip["bone_tracks"])==set(row["rig_bones"])-{"Root"}
            assert clip["duration_frames"]>0
            if name.startswith("throw_") and not name.startswith(("throw_reaction_","throw_landing")):
                assert clip["contact_frame"]==0
            assert all(len(keys)==clip["duration_frames"]+1 for keys in clip["bone_tracks"].values())
            for bone,keys in clip["bone_tracks"].items():
                for frame,key in enumerate(keys):
                    assert abs(key["time_s"]-frame/60)<.000001
                    q=key["rotation_quat"]
                    assert len(q)==4 and all(math.isfinite(v) for v in q)
                    assert abs(sum(v*v for v in q)-1)<.00001
                    if bone=="Hips":
                        assert len(key["position_m"])==3 and all(math.isfinite(v) for v in key["position_m"])
        if require_sources:
            assert digest(folder/row["saved_source"])==row["saved_source_sha256"]
            assert digest(ROOT/row["original_source"])==row["original_source_sha256"]
    return {"PASS":True,"rigs":18,"saved_actions":18*len(required),"source_binaries_checked":require_sources,
            "scope":"Saved/reopened source/runtime correspondence only; physical acting, art, native and device approval remain false"}


if __name__=="__main__":
    print(json.dumps(validate(Path(sys.argv[1]),"--runtime-only" not in sys.argv),indent=2))
