import type { HitEvent } from "@anime-aggressors/game-core";

export type CombatImpactVfxHandle = {
  element: string;
  strength: string;
  x: number;
  y: number;
};

export function hitEventToImpactVfx(event: HitEvent, victimX: number, victimY: number): CombatImpactVfxHandle {
  return {
    element: event.element,
    strength: event.hitStrength,
    x: victimX,
    y: victimY,
  };
}

export const ELEMENT_VFX_COLORS: Record<string, number> = {
  flame: 0xff4422,
  impact: 0xff8833,
  volt: 0xffee33,
  gale: 0x44ff88,
  frost: 0x66ccff,
  gravity: 0x8866ff,
  void: 0xaa44ff,
};
