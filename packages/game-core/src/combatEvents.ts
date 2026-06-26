export type CombatEventType =
  | "attack_startup"
  | "attack_active"
  | "hit_confirm"
  | "shield_hit"
  | "dodge_start"
  | "land"
  | "ko"
  | "cancel_window";

export type CombatEvent = {
  frame: number;
  type: CombatEventType;
  playerId: number;
  moveId?: string;
  targetId?: number;
  damage?: number;
};

export function createCombatEvent(
  frame: number,
  type: CombatEventType,
  playerId: number,
  extra: Partial<CombatEvent> = {},
): CombatEvent {
  return { frame, type, playerId, ...extra };
}
