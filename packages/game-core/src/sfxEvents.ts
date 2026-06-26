import type { CombatEventType } from "./combatEvents.js";

export type SfxEventType =
  | "attack_whiff"
  | "hit_confirm"
  | "shield_hit"
  | "dodge"
  | "jump"
  | "land"
  | "ko"
  | "menu_select"
  | "result";

export type SfxEvent = {
  frame: number;
  type: SfxEventType;
  playerId?: number;
  intensity?: number;
};

const COMBAT_TO_SFX: Partial<Record<CombatEventType, SfxEventType>> = {
  attack_active: "attack_whiff",
  hit_confirm: "hit_confirm",
  shield_hit: "shield_hit",
  dodge_start: "dodge",
  land: "land",
  ko: "ko",
};

export function combatEventToSfx(
  frame: number,
  combatType: CombatEventType,
  playerId: number,
): SfxEvent | null {
  const type = COMBAT_TO_SFX[combatType];
  if (!type) return null;
  return { frame, type, playerId };
}

export function createSfxEvent(
  frame: number,
  type: SfxEventType,
  playerId?: number,
  intensity = 1,
): SfxEvent {
  return { frame, type, playerId, intensity };
}
