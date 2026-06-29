import { HITLAG_DEFAULTS, type HitStrength } from "./combatTuning.js";

export function computeHitlag(strength: HitStrength): number {
  return HITLAG_DEFAULTS[strength] ?? HITLAG_DEFAULTS.light;
}

export function tickHitlag(state: { hitstopFrames: number }): void {
  if (state.hitstopFrames > 0) state.hitstopFrames -= 1;
}
