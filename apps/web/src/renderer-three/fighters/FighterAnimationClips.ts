import { getMoveById } from "@anime-aggressors/game-core";

export const ANIMATION_STATES = [
  "idle",
  "walk",
  "run",
  "dash",
  "jump",
  "doubleJump",
  "fall",
  "fastFall",
  "land",
  "neutralAttack",
  "sideAttack",
  "upAttack",
  "downAttack",
  "neutralSpecial",
  "sideSpecial",
  "upSpecial",
  "downSpecial",
  "superStartup",
  "superActive",
  "superRecovery",
  "shield",
  "auraCharge",
  "dodge",
  "grab",
  "throw",
  "hitstun",
  "launch",
  "ko",
  "victory",
  "defeat",
] as const;

export type AnimationState = (typeof ANIMATION_STATES)[number];

const LEGACY_MOVE_KEYS: Record<string, string> = {
  neutral_attack: "ember-neutralAttack",
  forward_attack: "ember-sideAttack",
  up_attack: "ember-upAttack",
  down_attack: "ember-downAttack",
  aerial_attack: "ember-neutralAir",
  special_attack: "ember-neutralSpecial",
  side_special: "ember-sideSpecial",
  dodge: "ember-dash",
  none: "ember-idle",
};

export function getAnimationKeyForMove(moveId: string): string {
  if (moveId === "none" || moveId === "dodge") {
    return LEGACY_MOVE_KEYS[moveId] ?? "ember-idle";
  }
  const move = getMoveById(moveId);
  if (move?.animationKey) return move.animationKey;
  return LEGACY_MOVE_KEYS[moveId] ?? `${moveId}-idle`;
}

export function slotToAnimationState(slot: string): AnimationState | undefined {
  if (slot === "super") return "superActive";
  if (slot.endsWith("Attack") || slot.endsWith("Air") || slot.endsWith("Special")) {
    return slot as AnimationState;
  }
  if (slot.startsWith("throw")) return "throw";
  if (slot === "grab") return "grab";
  return undefined;
}
