#!/usr/bin/env python3
"""Census repository evidence without converting declarations into runtime passes."""
import hashlib
import json
import struct
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GAME = ROOT / "game-godot"
OUT = ROOT / "artifacts/v1_closure"
GATES = {key: False for key in (
    "FINAL_CHARACTER_ART_PASS", "ANIMATION_TASTE_HUMAN_PASS", "GAME_FEEL_HUMAN_PASS",
    "VFX_TASTE_HUMAN_PASS", "SFX_MIX_HUMAN_PASS", "STORY_HUMAN_PASS", "V1_ANIME_HUMAN_PASS",
)}


def read(path):
    return json.loads(path.read_text()) if path.is_file() else {}


def evidence(path):
    if not path.is_file():
        return {"path": str(path.relative_to(ROOT)), "exists": False}
    data = path.read_bytes()
    return {"path": str(path.relative_to(ROOT)), "exists": True,
            "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}


def resource(path):
    return evidence(GAME / path.removeprefix("res://")) if path.startswith("res://") else {"path": path, "exists": False}


def glb(path):
    out = evidence(path)
    if out["exists"]:
        data = path.read_bytes()
        assert data[:4] == b"glTF"
        size, kind = struct.unpack_from("<II", data, 12)
        assert kind == 0x4E4F534A
        doc = json.loads(data[20:20 + size])
        out.update(joints=[doc["nodes"][j].get("name", "") for s in doc.get("skins", []) for j in s["joints"]],
                   animations=[a.get("name", "") for a in doc.get("animations", [])],
                   mesh_count=len(doc.get("meshes", [])))
    return out


def main():
    index = read(ROOT / "data/bibles/FIGHTER_BIBLE_INDEX.json")
    inventory = read(ROOT / "data/bibles/animation_inventory_v1.json")
    slots = [s["id"] for c in inventory["categories"] for s in c["slots"]]
    sfx = {(r["fighter_id"], r["move_id"]): r for r in read(GAME / "data/combat/v3_sfx_events.json")["rows"]}
    vfx = {(r["fighter_id"], r["move_id"]): r for r in read(GAME / "data/combat/v3_vfx_events.json")["rows"]}
    matrix, moves, animations = [], [], []
    for fighter in index["fighters"]:
        fid = fighter["id"]
        data = read(GAME / f"data/fighters/{fid}.json")
        manifest = read(GAME / f"data/moves/{fid}.json")
        declared = resource(data.get("animationManifestPath", ""))
        clip_manifest = read(ROOT / declared["path"]) if declared["exists"] else {}
        for slot in slots:
            animations.append({"fighter_id": fid, "slot": slot,
                               "exact_legacy_manifest_name": slot in clip_manifest.get("clips", []),
                               "authored_completion": False, "runtime_verified": False,
                               "note": "Names/aliases/procedural poses do not prove authored completion."})
        for move in manifest.get("moves", []):
            mid = move["move_id"]
            sound = sfx.get((fid, mid), {})
            visual = vfx.get((fid, mid), {})
            moves.append({"fighter_id": fid, "move_id": mid, "declared_identity": move.get("fighter_id"),
                          "startup": move.get("startup_frames"), "active": move.get("active_frames"),
                          "recovery": move.get("recovery_frames"), "hitstop": move.get("hitstop_frames"),
                          "camera": move.get("feedback", {}).get("camera_event"),
                          "vfx": visual, "sfx": sound,
                          "sfx_asset": resource(sound.get("asset", "")), "runtime_verified": False})
        spectrum = fid not in ("yin", "yang")
        for variant in ("male", "female"):
            candidate = GAME / f"assets/characters/golden_slice/{fid}/{variant}.glb"
            proxy = GAME / f"content/fighters/{fid}/model/{fid}_procedural_proxy.glb"
            model = glb(candidate if candidate.exists() else proxy)
            if fid in ("yin", "yang"):
                model = {"path": "game-godot/scripts/visual/v16_art_direction_body.gd", "exists": True,
                         "source": "ART_DIRECTION_CANDIDATE_V1_6", "skeleton_verified": False}
            forms = ("BASE", "PRISMATIC_GRAY", "BLACK_PUPPET", "WHITE_PUPPET") if spectrum else ("BASE", "COSMIC_BOSS")
            for form in forms:
                base = form == "BASE"
                matrix.append({"fighter_id": fid, "name": fighter["name"], "presentation": variant, "form": form,
                               "contracts": ["story", "competitive"] if base or form == "PRISMATIC_GRAY" else ["story_boss" if form == "COSMIC_BOSS" else "story"],
                               "current_base_model_evidence": model, "form_render_verified": False,
                               "current_form_status": "CANDIDATE_BASE_ONLY" if base else "NOT_IMPLEMENTED_ON_SHIPPING_PATH",
                               "portrait": resource(data.get("portraitPlaceholder", "")),
                               "move_count": len(manifest.get("moves", [])), "animation_slots_required": len(slots),
                               "animation_manifest": declared, "rig": "UNVERIFIED",
                               "V1_collectible_art": "REQUIRES_NEW_CANDIDATE_AND_OWNER_REVIEW",
                               "story_route": fid if spectrum else "SEVENFOLD_CONVERGENCE_UNLOCK",
                               "runtime_loadability": "UNTESTED", "web_build": "UNTESTED", "android_build": "UNTESTED",
                               "selection_battle_moves_hits_KO_results_return": "UNTESTED",
                               "owner_gates": GATES})
    baseline = {"schema": "anime_v1.baseline.v1", "baseline_sha": read(OUT / "authority_lock.json")["baseline_sha"],
                "census_source_sha": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
                "automated_ready": False, "owner_gates": GATES, "forms": matrix, "moves": moves, "animation_slots": animations,
                "limitations": ["Static source census only; no runtime proof implied.",
                                "Yin/Yang movement and frame values are TUNING_CANDIDATE; Ember references are residual defects.",
                                "Awakened/Ascended is not equivalent to Prismatic Gray."]}
    OUT.mkdir(exist_ok=True)
    (OUT / "baseline.json").write_text(json.dumps(baseline, indent=2) + "\n")
    lines = ["# Anime V1 baseline", "", f"Accepted main: `{baseline['baseline_sha']}`.",
             "Static evidence only. Automated readiness and all owner gates are false.", "",
             "| Fighter | Body | Form | Moves | Runtime |", "|---|---|---|---:|---|"]
    lines += [f"| {r['name']} | {r['presentation']} | {r['form']} | {r['move_count']} | UNTESTED |" for r in matrix]
    lines += ["", f"{len(matrix)} required presentations/forms; {len(moves)} move rows; {len(animations)} animation-slot rows.",
              "", "Machine-readable details and artifact hashes: `baseline.json`.",
              "Yin/Yang have no routine Puppet or Prismatic forms in supplied canon."]
    (OUT / "BASELINE.md").write_text("\n".join(lines) + "\n")
    print(f"Census: {len(matrix)} forms, {len(moves)} moves, {len(animations)} animation slots; readiness false.")


if __name__ == "__main__":
    main()
