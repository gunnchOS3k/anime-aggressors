"""Small derived index of existing authorities, never a replacement combo catalog.

Reports data/bindings separately from actual execution/art/network acceptance.
Reads public repository sources only. No imports, private art or native tools.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
IDS = ["ember-vale", "rook-ironside", "juno-spark", "kaia-windrow", "nix-calder", "orion-vell", "vesper-nyx", "yin", "yang"]


def ref(path):
    source = ROOT / path
    return {"path": path, "sha256": hashlib.sha256(source.read_bytes()).hexdigest()}


def build(engine_result=None):
    verified = {}
    engine = json.loads(engine_result.read_text()) if engine_result else {}
    # Accept only an actual retained successful engine result. Per-row evidence
    # remains bound to that SHA, never promoted to newer arbitrary revisions.
    if engine.get("PASS"):
        suite = engine.get("suites", {}).get("authored-special-links", {})
        for row in suite.get("result", {}).get("rows", []):
            if row.get("case") != "contact": continue
            for contact in row.get("contacts", []):
                if contact.get("result") == "hit":
                    verified.setdefault((row["fighter"], row["body"], contact["move"]), []).append({
                        "source_head":engine["source_head"], "frame":contact["frame"],
                        "contact_event":contact["contact_event"], "scope":"quiet-defender actual public-input contact; not active-CPU/visual/rollback approval"})
    roster = []
    for fid in IDS:
        path = f"game-godot/data/moves/{fid}.json"
        doc = json.loads((ROOT / path).read_text())
        moves = doc["moves"]
        bible = f"docs/bibles/fighters/{fid}.md"
        records = []
        for move in moves:
            mid = move["move_id"]
            records.append({"move_id":mid, "manifest_pointer":"/moves/"+str(len(records)),
                "input":move.get("input_command"), "ground_air":move.get("grounded_air"),
                "frames":[move.get(k) for k in ["startup_frames", "active_frames", "recovery_frames"]],
                "animation_id":move.get("animation_id"),
                "vfx_sfx_metadata":{k:move.get("feedback", {}).get(k) for k in ["vfx_event", "sfx_event"]},
                "explicit_hit_confirm_links":[w for w in move.get("cancel_windows", []) if w.get("to") and w.get("requires")=="hit_confirm"],
                "bodies":{body:{"data_binding":"MANIFEST_PRESENT",
                    "current_engine_contact_evidence":verified.get((fid, body, mid), []),
                    "native_original_animation":"PENDING_PRIVATE_STORAGE_AND_PRODUCED_ACTION_VERIFICATION",
                    "active_opponent_execution":"NOT_ESTABLISHED_BY_THIS_INDEX",
                    "multiplayer_rollback":"FULL_NATIVE_ROLLBACK_UNFINISHED",
                    "native_visual_review":"PENDING", "human_approved":False} for body in ["male", "female"]}})
        roster.append({"fighter":fid, "bible":ref(bible), "manifest":ref(path),
            "registered_BASE_move_count":len(moves), "body_presentations":["male", "female"], "moves":records})
    # Retain the existing TS authored route IDs/labels verbatim. They are a
    # different execution domain; do not silently convert them into Godot
    # cancel permissions or new universal taxonomy.
    route_path = "packages/game-core/src/moves/comboRoutes.ts"
    routes = []
    for line in (ROOT / route_path).read_text().splitlines():
        if not line.lstrip().startswith('{ id: "'): continue
        fields = {key:json.loads(value) for key, value in re.findall(r'(\w+):\s*("(?:[^"\\]|\\.)*"|\[[^\]]*\])', line)}
        if not all(key in fields for key in ["id", "fighterId", "name", "route"]):
            raise ValueError("Unparsed existing authored route; preserve source and update index parser")
        routes.append({**fields, "native_end_to_end_execution":"UNVERIFIED",
                       "native_cancel_authority":"Existing Godot manifest windows + Fighter resolver; this authored sequence is not an execution grant",
                       "native_visual_and_human_approval":False})
    return {"schema":"native-source-coverage/v1", "inventory_source_head":subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "scope":"Derived source-backed BASE inventory and preserved authored sequences; registered entries are NOT completed animated/playable/accepted moves",
        "totals":{"fighters":len(roster),"body_presentations":len(roster)*2,"BASE_records":sum(r["registered_BASE_move_count"] for r in roster),
                  "BASE_body_configurations":sum(r["registered_BASE_move_count"]*2 for r in roster), "TS_authored_sequences":len(routes)},
        "existing_sources":{"TS_routes":ref(route_path),"native_resolver":ref("game-godot/scripts/fighters/fighter.gd"),
                            "native_learning":ref("game-godot/scripts/ui/move_list_catalog.gd")},
        "evidence_source_head":engine.get("source_head") if engine.get("PASS") else None,
        "preserved_historical_evidence":"Earlier source-bound contact/Story/art receipts remain authoritative only for their own scope and SHA; no bulk revalidation or private-art access performed",
        "roster":roster,"preserved_authored_sequences":routes,
        "HUMAN_ART_APPROVED":False,"RUNTIME_PAIRED_CONTACT_VERIFIED":False,"RC2_READY":False,"V1_0_0_RELEASE_AUTHORIZED":False}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--engine-result", type=Path)
    args = parser.parse_args()
    result = build(args.engine_result)
    args.output.write_text(json.dumps(result, separators=(",", ":"))+"\n")
    print(json.dumps(result["totals"]))
