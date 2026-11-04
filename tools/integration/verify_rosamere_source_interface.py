#!/usr/bin/env python3
"""Read immutable Git objects to verify the additive Rosamere source contract.

This never checks out, imports, merges, executes, or modifies Cursor code/art.
It is not runtime, unlock-security, gameplay, animation, or human acceptance.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

CURSOR_SHA = "1d7eda52a49cc394d6865353b36034ab11663c41"
CODEX_SHA = "56e95459f2af8358750f302369f5a71193b74640"
CURSOR_BRANCH = "cursor/continuation-v1-batch4-stages-20261030"
ORIGINAL_NINE = (
    "ember-vale", "rook-ironside", "juno-spark", "kaia-windrow",
    "nix-calder", "orion-vell", "vesper-nyx", "yin", "yang",
)
FORMS = ("FAMILIAR_ROSE", "FIRST_BLOOM", "EVERLASTING_ORIGIN")
COMPETITIVE = "COMPETITIVE_SELF_LIMITED"
SPECIALS = {
    "bloom_seed": "special_neutral", "petal_constellation": "special_forward",
    "first_dawn": "special_up", "gentle_reversal": "special_down",
}
UNBOUND = {
    "quiet_embrace", "a_world_in_bloom", "before_there_was_time",
    "the_first_permission", "mythic_everything_again",
}


def function_lines(source: str, name: str) -> list[str]:
    """Extract a top-level GDScript function for explicit source signatures only.

    This is not a GDScript parser or a proof that a branch executes correctly.
    Ignore blank/full-comment lines; retain statements and their indentation.
    """
    result: list[str] = []
    inside = False
    for line in source.splitlines():
        if re.match(r"^(?:static )?func " + re.escape(name) + r"\(", line):
            inside = True
            continue
        if inside and line and not line[0].isspace() and not line.startswith("#"):
            break
        if inside and line.strip() and not line.lstrip().startswith("#"):
            result.append(line.rstrip())
    return result


class Verify:
    def __init__(self, repo: Path, cursor: str, codex: str):
        self.repo = repo
        self.cursor = self.resolve(cursor)
        self.codex = self.resolve(codex)
        self.sources: dict[str, dict[str, dict[str, object]]] = {}
        self.checks: list[dict[str, object]] = []

    def git(self, *args: str) -> bytes:
        # Only read-only Git subcommands are ever called by this program.
        return subprocess.check_output(["git", "-C", str(self.repo), *args], stderr=subprocess.PIPE)

    def resolve(self, sha: str) -> str:
        if not re.fullmatch(r"[0-9a-f]{40}", sha):
            raise ValueError("Use an immutable full 40-character source SHA, not a moving branch")
        actual = self.git("rev-parse", "--verify", sha + "^{commit}").decode().strip()
        if actual != sha:
            raise ValueError("Source identity mismatch")
        return actual

    def read(self, sha: str, path: str) -> bytes:
        raw = self.git("show", sha + ":" + path)
        if len(raw) > 2 * 1024 * 1024:
            raise ValueError("Source contract object exceeds the 2 MiB read bound: " + path)
        self.sources.setdefault(sha, {})[path] = {
            "bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest(),
        }
        return raw

    def document(self, path: str) -> dict:
        value = json.loads(self.read(self.cursor, path))
        if not isinstance(value, dict):
            raise ValueError("Expected JSON object: " + path)
        return value

    def check(self, passed: bool, label: str, **details: object) -> None:
        self.checks.append({"check": label, "pass": bool(passed), **details})

    def run(self) -> dict:
        roster = self.document("game-godot/data/fighters/roster.json")
        self.check(roster.get("fighters") == [*ORIGINAL_NINE, "rosamere"], "ten_distinct_canonical_fighter_identities")
        self.check(roster.get("secret") == ["rosamere"], "Rosamere_is_additive_secret_tenth")
        retained = []
        for fighter in ORIGINAL_NINE:
            path = f"game-godot/data/moves/{fighter}.json"
            before = self.read(self.codex, path)
            after = self.read(self.cursor, path)
            rows = json.loads(after).get("moves", [])
            ids = [row.get("move_id") for row in rows]
            self.check(before == after and len(rows) == len(set(ids)) == 24,
                       fighter + "_original_move_manifest_preserved_byte_for_byte")
            retained.extend(ids)
        fighter = self.document("game-godot/data/fighters/rosamere.json")
        moves = self.document("game-godot/data/moves/rosamere.json")
        forms = self.document("game-godot/data/forms/rosamere.json")
        animations = self.document("game-godot/data/fighters/rosamere_animations.json")
        self.check(fighter.get("id") == moves.get("fighter_id") == forms.get("fighter_id") == animations.get("fighter_id") == "rosamere", "fighter_move_form_animation_identity_agrees")
        self.check(set(fighter.get("body_variants", [])) == {"female", "male"}, "both_body_presentations_declared_not_runtime_verified")
        self.check(fighter.get("moveListPath") == "res://data/moves/rosamere.json" and fighter.get("forms_path") == "res://data/forms/rosamere.json", "existing_runtime_manifest_paths_match")
        rows = moves.get("moves", [])
        by_id = {row.get("move_id"): row for row in rows}
        bound = {key for key, row in by_id.items() if row.get("input_command", "")}
        unbound = set(by_id) - bound
        self.check(len(rows) == len(by_id) == 29 and len(bound) == 24 and unbound == UNBOUND,
                   "actual_move_inventory_and_unbound_signature_gaps", bound_ids=sorted(bound), unbound_ids=sorted(unbound))
        self.check(all(by_id.get(move, {}).get("input_command") == command for move, command in SPECIALS.items()), "character_owned_special_identifiers_retained")
        self.check(forms.get("ui_manifestations") == list(FORMS) and set(forms.get("forms", {})) == set(FORMS), "exactly_three_manifestations_not_four")
        self.check(forms.get("default_form") == FORMS[0] and forms.get("form_ladder") == list(FORMS[:2]) and forms.get("story_form_ladder") == list(FORMS), "competitive_and_story_ladders_distinguished")
        contract = forms.get("gameplay_contracts", {}).get(COMPETITIVE, {})
        familiar = forms.get("forms", {}).get(FORMS[0], {})
        self.check(contract.get("attaches_to_form") == FORMS[0] and contract.get("is_story_form") is False and familiar.get("gameplay_contract_id") == COMPETITIVE and contract.get("can_lose") is True and contract.get("invincible") is False, "fair_competitive_contract_attached_to_Familiar_Rose")
        eternal = forms.get("forms", {}).get(FORMS[2], {})
        self.check({"versus", "ranked"} <= set(eternal.get("forbid_modes", [])) and not ({"versus", "ranked"} & set(eternal.get("permitted_modes", []))) and eternal.get("ranked_allowed") is False and eternal.get("mythic_consent_required") is True, "Everlasting_competitive_exclusion_and_mythic_consent_declared")
        self.check(forms.get("transform_rules", {}).get("mythic_party_consent_required_for_everlasting") is True, "existing_mythic_transform_consent_requirement")
        self.check(fighter.get("art_status", {}).get("HUMAN_ART_APPROVED") is False and forms.get("art_status", {}).get("HUMAN_ART_APPROVED") is False and forms.get("tuning_status") == "BALANCE_NOT_APPROVED", "human_art_and_balance_acceptance_remain_pending")
        self.check(fighter.get("authorship", {}).get("assetStatuses", {}).get("model_glb") == "NOT_AUTHORED" and animations.get("modelPath") == "res://assets/characters/collectible_v1/yin/male/BASE.glb", "nonoriginal_model_fallback_is_open_art_gap_not_finished_Rosamere_art")
        campaign = self.read(self.cursor, "game-godot/scripts/story/v1_campaign_runtime.gd").decode()
        rebuild = function_lines(campaign, "_rebuild_unlocks")
        reveal = function_lines(campaign, "secret_reveal_earned")
        self.check('\tprogress["rosamere_unlocked"] = secret_reveal_earned("rosamere")' in rebuild,
                   "source_signature_unlock_recomputed_from_reveal_helper_not_runtime_security_proof")
        self.check(bool(reveal) and any('node_id not in entry.get("completed", [])' in line for line in reveal) and any('node.get("kind") == "STORY_BATTLE"' in line and 'get("qualifying", false)' in line for line in reveal) and any('node.get("fighter_hint", "")' in line and '== fighter_id' in line for line in reveal),
                   "source_signature_completed_prefix_qualifying_battles_and_fighter_reveal_present_not_execution_proof")
        policy = self.read(self.cursor, "game-godot/scripts/combat/rosamere_form_selection.gd").decode()
        norm = function_lines(policy, "normalize_selection")
        permitted = function_lines(policy, "permitted_in_mode")
        self.check(any('id.is_empty() or id == CONTRACT_COMPETITIVE' in line for line in norm) and any('"form_id": FORM_FAMILIAR' in line for line in norm) and any('"fourth_form": false' in line for line in norm), "source_signature_technical_contract_alias_preserves_manifestation_identity")
        self.check(any('resolved == FORM_EVERLASTING and not mythic_consent' in line for line in permitted) and any('resolved == FORM_EVERLASTING and mode_key in ["versus", "ranked"]' in line for line in permitted), "source_signature_existing_mode_and_consent_gates_present_not_runtime_proof")
        for path in ["game-godot/scripts/net/experimental/flat_combat_resim.gd", "game-godot/scripts/net/experimental/lan_resim_bridge.gd", "game-godot/scripts/net/experimental/human_seat_policy.gd"]:
            source = self.read(self.cursor, path).decode()
            if path.endswith("lan_resim_bridge.gd"):
                self.check(re.search(r"(?m)^const SHIPPING_BACKEND_ENABLED := false$", source) is not None, "shadow_LAN_bridge_does_not_enable_shipping_restore")
        failures = [row["check"] for row in self.checks if not row["pass"]]
        return {
            "schema": "anime_rosamere_source_interface/v1", "PASS": not failures,
            "status": "SOURCE_CONTRACT_VERIFIED" if not failures else "SOURCE_CONTRACT_FAILED",
            "cursor_branch_reference": CURSOR_BRANCH, "cursor_source_sha": self.cursor, "codex_comparison_sha": self.codex,
            "source_sha256": self.sources, "checks": self.checks, "failures": failures,
            "inventory": {"original_identities": 9, "original_BASE_records": len(retained), "additive_Rosamere_records": len(rows), "Rosamere_input_bound_records": len(bound), "declared_manifestations": list(FORMS)},
            "handoff": {
                "Cursor_owns": ["Rosamere", "Story", "Trials", "presentation", "stages", "normal-game integration"],
                "shared_conflict_paths_require_review_not_automatic_merge": ["game-godot/scripts/fighters/fighter.gd", "game-godot/scripts/battle/battle_scene.gd", "game-godot/scripts/core/GameState.gd", "game-godot/scripts/story/v1_campaign_runtime.gd", "game-godot/scripts/net/lan_session.gd", "game-godot/scripts/net/experimental/flat_combat_trial.gd"],
                "existing_shadow_netcode_requires_reuse_review": ["flat_combat_resim.gd", "lan_resim_bridge.gd", "human_seat_policy.gd"],
                "existing_human_seat_policy_scope": "two humans; not 4/6/8 independent clients",
            },
            "scope": "Read-only immutable Git-object and JSON compatibility checks, including explicitly limited source signatures. No checkout/import/runtime/saves/inputs/native/device/art/earned unlock/secure network or rollback acceptance.",
            "remaining": ["Rosamere engine and ordinary-input verification at the exact Cursor commit", "original Rosamere model and move-specific art", "five unbound signature records need source-authority execution review", "conflict-aware code integration", "2/4/6/8 independently controlled client matrix", "shipping whole-world rollback"],
            "HUMAN_ART_APPROVED": False, "HUMAN_GAMEPLAY_PASS": False,
            "RUNTIME_PAIRED_CONTACT_VERIFIED": False, "RC2_READY": False, "V1_0_0_RELEASE_AUTHORIZED": False,
        }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--cursor-sha", default=CURSOR_SHA)
    parser.add_argument("--codex-sha", default=CODEX_SHA)
    args = parser.parse_args()
    try:
        result = Verify(args.repo, args.cursor_sha, args.codex_sha).run()
    except (ValueError, KeyError, TypeError, json.JSONDecodeError, subprocess.CalledProcessError) as exc:
        result = {"schema": "anime_rosamere_source_interface/v1", "PASS": False, "status": "SOURCE_CONTRACT_FAILED", "error": str(exc), "scope": "Source-only verifier; no runtime or acceptance claim."}
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["PASS"] else 1


if __name__ == "__main__":
    sys.exit(main())
