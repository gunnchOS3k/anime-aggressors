export type AuraChargeLevel = 0 | 1 | 2 | 3;

export type AuraChargeState = {
  current: number;
  max: number;
  level: AuraChargeLevel;
  charging: boolean;
  overcharged: boolean;
  cooldownFrames: number;
};

export const AURA_MAX = 100;
export const AURA_CHARGE_RATE = 2;
export const AURA_DECAY_RATE = 1;
export const AURA_OVERCHARGE_COOLDOWN = 90;
export const AURA_HEAVY_HIT_LOSS = 18;
export const AURA_INTERRUPT_LOSS = 12;

export function createDefaultAuraState(): AuraChargeState {
  return {
    current: 0,
    max: AURA_MAX,
    level: 0,
    charging: false,
    overcharged: false,
    cooldownFrames: 0,
  };
}

export function auraLevelFromCurrent(current: number): AuraChargeLevel {
  if (current >= 85) return 3;
  if (current >= 50) return 2;
  if (current >= 25) return 1;
  return 0;
}

export function isSuperReady(aura: AuraChargeState): boolean {
  return aura.level >= 3 && aura.cooldownFrames <= 0;
}
