#!/usr/bin/env python3
"""Compile source-derived routes with explicit, versioned owner First Loss authority."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PACK = ROOT / "docs/anime-aggressors/creative/authority_pack_v1"
OUT = ROOT / "game-godot/data/story/v1_campaign.json"


def build():
    authority = json.loads((PACK / "STORY_CAMPAIGN_MANIFEST.json").read_text())
    decisions = json.loads((ROOT / authority["first_loss_decision"]).read_text())
    if decisions["selected"] != authority["first_loss_selected"]:
        raise ValueError("Story authority disagrees with selected owner canon")
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
                node["first_loss"] = authority["first_loss_selected"][anchor]
                node["canon_status"] = decisions["status"]
                node["title"] = "First Loss — " + names[node["first_loss"]]
                node["consequence"] = authority["route_consequences"][anchor]
                node["copy_status"] = "DRAFT_OWNER_REVIEW"
                node["body"] = node["consequence"]["circumstance"]
            if key == "catastrophe":
                node.update(kind="INTERACTIVE_DIALOGUE", implemented=True, body="Yin sees seven differences capable of conflict. Yang sees seven identities to reconcile through imposed definition. The Seven attack; ordinary damage cannot resolve the cosmic contract.", expression="shock")
                node.pop("block_reason", None)
            if key == "impossible_battle_1":
                node.update(kind="STORY_BATTLE", implemented=True, opponent="yin", additional_opponent="yang", stage="void-pier", objective_contract="COSMIC_SURVIVAL", survive_seconds=24, objective="Survive the Yin/Yang encounter. Ordinary damage cannot defeat these story manifestations.", body="Survive, evade and recover. The team itself is becoming the battleground. The outcome leads to the First Loss, not victory over Yin or Yang.", expression="battle_intent")
                node.pop("block_reason", None)
            if key == "first_loss" and anchor == "kaia-windrow":
                node.update(kind="INTERACTIVE_DIALOGUE", implemented=True, essence_after=1, body="Rook tries to carry the failure himself. His sacrifice is the tragic extreme of his protective virtue. He leaves the first Essence. Kaia remains Kaia, now carrying one other perspective.", expression="grief")
                node.pop("block_reason", None)
            nodes.append(node)
        profile = authority["route_consequences"][anchor]
        lost = authority["first_loss_selected"][anchor]
        puppets = [f for f in opponents if f != lost]
        for node in nodes:
            key = node["id"].split(":")[-1]
            node["watch_seconds"] = 14 if node["kind"] == "STORY_BATTLE" else 10
            node["expression"] = node.get("expression", "determination" if node["kind"] == "STORY_BATTLE" else "cinematic_closeup")
            if key in {"first_loss", "puppet_imbalance", "first_release", "equilibrium", "dual_release_1", "dual_release_2", "prismatic_gray", "impossible_battle_2"}:
                node.update(kind="STORY_BATTLE", implemented=True, stage="void-pier", opponent=lost if key == "first_loss" else puppets[0],
                            objective_contract={"first_loss":"FIRST_LOSS", "puppet_imbalance":"PUPPET_IMBALANCE", "first_release":"FIRST_RELEASE", "equilibrium":"PUPPET_EQUILIBRIUM", "dual_release_1":"PAIRED_RELEASE", "dual_release_2":"PAIRED_RELEASE", "prismatic_gray":"PRISMATIC_TRANSFORMATION", "impossible_battle_2":"GRAY_DEMONSTRATION"}[key],
                            puppets={"yin":puppets[:3], "yang":puppets[3:]}, consequence=profile,
                            objective=profile["objective"] if key == "first_loss" else {"puppet_imbalance":"Disrupt the dominant Yin side: land a hit, then guard the center. Five puppets remain divided 3 against 2.", "first_release":"Choose a weakened Yin puppet (40% damage), approach and press Special to release. A player-earned KO also releases it. Restore 2 against 2.", "equilibrium":"Guard the center for eight seconds while both Puppet sides remain represented.", "dual_release_1":"Release one Yin and one Yang puppet: weaken then Special nearby, or earn their KOs.", "dual_release_2":"Release the final opposite-force pair. Six distinct perspectives remain.", "prismatic_gray":"Carry six perspectives through the marked spectrum nodes, then hold Shield to integrate your own identity.", "impossible_battle_2":"Evade the cosmic pair and demonstrate attack, guard and purposeful traversal. Greater damage cannot settle the conflict."}[key],
                            body=profile["circumstance"] if key == "first_loss" else profile["essence"] if key.startswith("dual") or key == "first_release" else profile["gray"] if key == "prismatic_gray" else profile["consequence"],
                            copy_status="DRAFT_OWNER_REVIEW", cinematic_framing=profile["camera"], presentation_status="CANDIDATE_ANI_03_04_PENDING")
                node.pop("block_reason", None)
                if key == "first_loss": node["essence_after"] = 1
                if key == "first_release": node["essence_after"] = 2
                if key == "dual_release_1": node["essence_after"] = 4
                if key == "dual_release_2": node["essence_after"] = 6
                if key == "prismatic_gray": node["form_after"] = "PRISMATIC_GRAY"
                if key == "impossible_battle_2": node.update(opponent="yin", additional_opponent="yang", survive_seconds=18)
            if key in {"epilogue", "unlock"}:
                node.update(kind="INTERACTIVE_DIALOGUE", implemented=True, body=profile["aftermath"] + " " + profile["growth"], copy_status="DRAFT_OWNER_REVIEW", expression="determination")
                node.pop("block_reason", None)
                if key == "unlock": node["route_complete"] = True
        routes.append({"id": anchor, "title": "The Green Between" if anchor == "kaia-windrow" else names[anchor] + " — Prismatic Route",
                       "watch_title": "Anime Aggressors OVA — Kaia Route" if anchor == "kaia-windrow" else names[anchor].split()[0] + " Route Variation",
                       "watch_role": "PRIMARY_OVA" if anchor == "kaia-windrow" else "CAMPAIGN_VARIATION",
                       "anchor": anchor, "lesson": authority["route_lessons"][anchor], "recruitment_pairs": pairs,
                       "first_loss": {"fighter": authority["first_loss_selected"][anchor], "status": decisions["status"], "decision_id": decisions["decision_id"]},
                       "consequence": authority["route_consequences"][anchor],
                       "nodes": nodes})
    routes.append({"id": "sevenfold-convergence", "title": "Sevenfold Convergence", "anchor": "kaia-windrow",
                   "requires": authority["spectral_order"], "nodes": [
                       {"id":"sevenfold:reunion", "title":"Seven Gray Fighters Reunite", "kind":"STORY_BATTLE", "implemented":True, "objective_contract":"SEVENFOLD_REUNION", "opponent":"ember-vale", "stage":"skyline-arena", "objective":"Reach each of the six Gray allies; demonstrate a society of distinct mediators.", "copy_status":"DRAFT_OWNER_REVIEW"},
                       {"id":"sevenfold:trial", "title":"Sevenfold Trial", "kind":"STORY_BATTLE", "implemented":True, "objective_contract":"SEVENFOLD_TRIAL", "opponent":"ember-vale", "stage":"skyline-arena", "objective":"Control each Gray identity in sequence; win a real exchange before passing leadership.", "copy_status":"DRAFT_OWNER_REVIEW"},
                       {"id":"sevenfold:equilibrium", "title":"Yin/Yang Equilibrium", "kind":"STORY_BATTLE", "implemented":True, "objective_contract":"SEVENFOLD_EQUILIBRIUM", "opponent":"yin", "additional_opponent":"yang", "stage":"void-pier", "survive_seconds":21, "objective":"Alternate guarded visits to Yin and Yang three times; survive without erasing either principle.", "copy_status":"DRAFT_OWNER_REVIEW"},
                       {"id":"sevenfold:conversation", "title":"A Society of Mediators", "kind":"INTERACTIVE_DIALOGUE", "implemented":True, "body":"Seven distinct perspectives remain. Rest can protect boundaries; creation can support expression. Neither principle must consume the people it supports.", "copy_status":"DRAFT_OWNER_REVIEW"},
                       {"id":"sevenfold:unlock", "title":"Yin + Yang Playable Unlock", "kind":"INTERACTIVE_DIALOGUE", "implemented":True, "cosmic_unlock":True, "body":"Yin and Yang join as separate competitive identities under normalized rules. Their cosmic Story contracts remain separate.", "copy_status":"DRAFT_OWNER_REVIEW"}]})
    return {"schema": "anime_v1.campaign.v1", "authority": str(PACK.relative_to(ROOT)),
            "canon_decision": decisions["decision_id"], "first_loss_selected": decisions["selected"],
            "copy_status": "DRAFT_OWNER_REVIEW", "implementation_complete": False, "gameplay_graph_integrated": True, "presentation_status": "CANDIDATE_ANI_03_04_PENDING", "watch_authority": "SHARED_ROUTE_GRAPH",
            "root_route": "kaia-windrow", "spectral_order": authority["spectral_order"],
            "essence_progression": authority["essence_progression"], "routes": routes}


if __name__ == "__main__":
    OUT.write_text(json.dumps(build(), indent=2) + "\n")
    print("Compiled 145 campaign nodes with objective contracts; runtime validation is required before completion claims.")
