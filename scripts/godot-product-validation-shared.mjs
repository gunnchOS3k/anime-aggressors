import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotRoot = path.join(repoRoot, "game/godot");
const dataRoot = path.join(godotRoot, "data");

export const FIGHTERS = [
  "ember-vale",
  "rook-ironside",
  "juno-spark",
  "kaia-windrow",
  "nix-calder",
  "orion-vell",
  "vesper-nyx",
];

export const REQUIRED_MOVE_INPUTS = [
  "neutral_attack", "side_attack", "up_attack", "down_attack", "dash_attack",
  "neutral_air", "forward_air", "back_air", "up_air", "down_air",
  "neutral_special", "side_special", "up_special", "down_special",
  "grab", "throw", "super",
];

export const REQUIRED_MOVE_FIELDS = [
  "hit_socket", "vfx_socket", "hurtbox_profile",
  "startup_frames", "active_frames", "recovery_frames",
  "damage", "base_knockback", "knockback_growth",
  "hitlag", "hitstun", "camera_impulse", "audio_event", "vfx_event",
];

export const REQUIRED_SOCKETS = [
  "right_fist", "left_fist", "right_foot", "left_foot",
  "weapon_tip", "chest", "head", "aura_core", "ground_contact", "center_mass",
];

export const COMBO_DIFFICULTIES = {
  beginner: 3,
  intermediate: 3,
  advanced: 2,
  aura: 1,
  super: 1,
};

export function loadJson(relPath) {
  const full = path.join(dataRoot, relPath);
  if (!fs.existsSync(full)) return null;
  return JSON.parse(fs.readFileSync(full, "utf8"));
}

export function loadMoveCatalog() {
  return loadJson("moves/move_catalog.json");
}

export function loadComboCatalog() {
  return loadJson("combos/combo_catalog.json");
}

export function loadAnimationContract() {
  return loadJson("animations/animation_contract.json");
}

export function loadStageCatalog() {
  return loadJson("stages/stage_catalog.json");
}

export function getFighterMoves(catalog, fighterId) {
  const moves = catalog?.[fighterId] ?? {};
  const byInput = {};
  for (const [key, move] of Object.entries(moves)) {
    const input = move.input ?? key;
    if (!byInput[input] || key === input) {
      byInput[input] = move;
    }
  }
  return byInput;
}

export function formatMissing(fighterId, moveId, field, filePath) {
  return `${filePath}: fighter_id=${fighterId} move_id=${moveId} missing field=${field}`;
}
