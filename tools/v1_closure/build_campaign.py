#!/usr/bin/env python3
"""Compile source-derived route geometry; draft adaptation never settles open canon."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PACK = ROOT / "docs/anime-aggressors/creative/authority_pack_v1"
OUT = ROOT / "game-godot/data/story/v1_campaign.json"


def build():
    authority = json.loads((PACK / "STORY_CAMPAIGN_MANIFEST.json").read_text())
    fighters = json.loads((ROOT / "data/bibles/FIGHTER_BIBLE_INDEX.json").read_text())["fighters"]
    names = {f["id"]: f["name"] for f in fighters}
    stages = ["skyline-arena", "neon-rooftops", "cascade-foundry", "void-pier", "ember-courtyard", "skyline-arena"]
    routes = []
    for anchor in authority["spectral_order"]:
        pairs = authority["prismatic_route_pairs"][anchor]
        opponents = [fighter for pair in pairs for fighter in pair]
        prefix = anchor + ":"
        nodes = [{"id": prefix + "prologue", "title": "Prologue — " + names[anchor],
                  "kind": "STORY_BATTLE", "implemented": True, "opponent": opponents[0], "stage": "skyline-arena",
                  "objective": "Win the opening encounter.", "copy_status": "DRAFT_ADAPTATION",
                  "body": "Explore the Anchor's movement and power. " + authority["route_lessons"][anchor].replace("_", " ").capitalize() + "."}]
        for i, opponent in enumerate(opponents):
            nodes.append({"id": prefix + "recruit:" + opponent, "title": "Encounter — " + names[opponent],
                          "kind": "STORY_BATTLE", "implemented": True, "opponent": opponent, "stage": stages[i],
                          "recruit": opponent, "pair_index": i // 2,
                          "objective": "Win this encounter to continue the recruitment pair.",
                          "copy_status": "DRAFT_ADAPTATION", "body": "Balanced pair %d: %s and %s." %
                          (i // 2 + 1, names[pairs[i // 2][0]], names[pairs[i // 2][1]])})
        nodes.append({"id": prefix + "accord", "title": "Sevenfold Accord", "kind": "INTERACTIVE_DIALOGUE",
                      "implemented": True, "copy_status": "DRAFT_ADAPTATION",
                      "body": "The seven stand together. Their differences remain. The Accord is imperfect but real."})
        later = [
            ("catastrophe", "The Catastrophe", "AFTERMATH"),
            ("impossible_battle_1", "Impossible Yin/Yang Battle I", "OBJECTIVE_BATTLE"),
            ("first_loss", "First Loss — Rook Ironside" if anchor == "kaia-windrow" else "First Loss", "AFTERMATH"),
            ("puppet_imbalance", "Five Puppets — 3 against 2", "OBJECTIVE_BATTLE"),
            ("first_release", "First Release", "OBJECTIVE_BATTLE"),
            ("equilibrium", "Restored 2v2 Equilibrium", "OBJECTIVE_BATTLE"),
            ("dual_release_1", "Dual Release I", "OBJECTIVE_BATTLE"),
            ("dual_release_2", "Dual Release II — Six Essences", "OBJECTIVE_BATTLE"),
            ("prismatic_gray", "Prismatic Gray — " + names[anchor], "TRANSFORMATION"),
            ("impossible_battle_2", "Impossible Yin/Yang Battle II", "OBJECTIVE_BATTLE"),
            ("epilogue", "Equilibrium — Route Resolution", "AFTERMATH"),
            ("unlock", "Prismatic Gray Unlock", "UNLOCK"),
        ]
        for key, title, kind in later:
            node = {"id": prefix + key, "title": title, "kind": kind, "implemented": False,
                    "block_reason": "This chapter's encounter and presentation are still being built.",
                    "copy_status": "DRAFT_ADAPTATION"}
            if key == "first_loss":
                node["first_loss"] = "rook-ironside" if anchor == "kaia-windrow" else None
                node["canon_status"] = "CANONICAL" if anchor == "kaia-windrow" else "OPEN_CANON"
                if anchor != "kaia-windrow":
                    node["block_reason"] = "The owner must approve this Anchor's First Loss."
            nodes.append(node)
        routes.append({"id": anchor, "title": "The Green Between" if anchor == "kaia-windrow" else names[anchor] + " — Prismatic Route",
                       "anchor": anchor, "lesson": authority["route_lessons"][anchor], "recruitment_pairs": pairs,
                       "first_loss": authority["root_first_loss"] if anchor == "kaia-windrow" else {"fighter": None, "status": "OPEN_CANON"},
                       "nodes": nodes})
    routes.append({"id": "sevenfold-convergence", "title": "Sevenfold Convergence", "anchor": "kaia-windrow",
                   "requires": authority["spectral_order"], "nodes": [
                       {"id": "sevenfold:" + key, "title": title, "kind": kind, "implemented": False,
                        "block_reason": "Seven completed Gray routes and the Convergence encounter are required."}
                       for key, title, kind in [("reunion", "Seven Gray Fighters Reunite", "CINEMATIC"),
                                                ("trial", "Sevenfold Trial", "OBJECTIVE_BATTLE"),
                                                ("equilibrium", "Yin/Yang Equilibrium", "OBJECTIVE_BATTLE"),
                                                ("conversation", "A Society of Mediators", "INTERACTIVE_DIALOGUE"),
                                                ("unlock", "Yin + Yang Playable Unlock", "UNLOCK")]]})
    return {"schema": "anime_v1.campaign.v1", "authority": str(PACK.relative_to(ROOT)),
            "copy_status": "DRAFT_ADAPTATION", "implementation_complete": False,
            "root_route": "kaia-windrow", "spectral_order": authority["spectral_order"],
            "essence_progression": authority["essence_progression"], "routes": routes}


if __name__ == "__main__":
    OUT.write_text(json.dumps(build(), indent=2) + "\n")
    print("Compiled 7 routes + Convergence; 49 battle nodes wired for the opening checkpoint.")
