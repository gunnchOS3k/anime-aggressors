import type { DefaultFighterId } from "../defaultFighters.js";
import type { CombatMoveData } from "./defaultMoveCatalog.js";
import { getCatalogMove } from "./defaultMoveCatalog.js";

export type FighterMoveOverrides = Partial<
  Pick<
    CombatMoveData,
    | "damage"
    | "baseKnockback"
    | "knockbackGrowth"
    | "startup"
    | "active"
    | "recovery"
    | "hitboxWidth"
    | "hitboxHeight"
    | "hitboxOffsetX"
    | "angleDeg"
  >
> & {
  spawnsProjectile?: boolean;
  projectileDamage?: number;
  projectileKnockback?: number;
};

const OVERRIDES: Partial<Record<DefaultFighterId, Partial<Record<string, FighterMoveOverrides>>>> = {
  "ember-vale": {
    neutral_attack: { damage: 4, baseKnockback: 5 },
    special_attack: { damage: 11, baseKnockback: 13, recovery: 16 },
    side_special: { damage: 10, baseKnockback: 12, startup: 9 },
  },
  "rook-ironside": {
    neutral_attack: { damage: 5, baseKnockback: 7 },
    forward_attack: { damage: 9, baseKnockback: 11 },
    special_attack: { damage: 14, baseKnockback: 16, startup: 11, recovery: 22 },
    side_special: { damage: 15, baseKnockback: 18, angleDeg: 25 },
  },
  "juno-spark": {
    neutral_attack: { damage: 3, baseKnockback: 4, startup: 3, recovery: 8 },
    forward_attack: { damage: 5, baseKnockback: 6 },
    dash_attack: { damage: 7, baseKnockback: 8, startup: 5 },
    special_attack: { damage: 8, baseKnockback: 9, startup: 7, recovery: 14 },
    side_special: { damage: 9, baseKnockback: 10, startup: 8 },
  },
  "kaia-windrow": {
    neutral_attack: { damage: 4, baseKnockback: 5 },
    up_air: { damage: 8, baseKnockback: 9, hitboxOffsetX: 0 },
    special_attack: { damage: 9, baseKnockback: 10, hitboxWidth: 52, hitboxOffsetX: 40 },
    side_special: { damage: 10, baseKnockback: 11, hitboxOffsetX: 48 },
  },
  "vesper-nyx": {
    neutral_attack: { damage: 3, baseKnockback: 4 },
    special_attack: {
      damage: 7,
      baseKnockback: 8,
      startup: 10,
      active: 3,
      recovery: 20,
      hitboxWidth: 44,
      spawnsProjectile: true,
      projectileDamage: 6,
      projectileKnockback: 7,
    },
    side_special: { damage: 9, baseKnockback: 10, hitboxOffsetX: 48 },
  },
  /** TUNING_CANDIDATE */
  yin: {
    neutral_attack: { damage: 4, baseKnockback: 5, startup: 6 },
    special_attack: {
      damage: 8,
      baseKnockback: 7,
      startup: 12,
      active: 4,
      recovery: 18,
      hitboxWidth: 48,
      spawnsProjectile: true,
      projectileDamage: 5,
      projectileKnockback: 6,
    },
    side_special: { damage: 8, baseKnockback: 9, hitboxOffsetX: 40 },
  },
  /** TUNING_CANDIDATE */
  yang: {
    neutral_attack: { damage: 5, baseKnockback: 6, startup: 5 },
    special_attack: {
      damage: 9,
      baseKnockback: 9,
      startup: 9,
      active: 3,
      recovery: 16,
      hitboxWidth: 52,
      spawnsProjectile: true,
      projectileDamage: 7,
      projectileKnockback: 8,
    },
    side_special: { damage: 10, baseKnockback: 11, hitboxOffsetX: 50 },
  },
};

function normalizeFighterId(fighterId: string): string {
  return fighterId.replace(/^created:/, "");
}

export function getFighterMoveOverrides(
  fighterId: string,
  moveId: string,
): FighterMoveOverrides | undefined {
  const id = normalizeFighterId(fighterId) as DefaultFighterId;
  return OVERRIDES[id]?.[moveId];
}

export function applyFighterMoveOverrides(
  fighterId: string,
  moveId: string,
  base: CombatMoveData,
): CombatMoveData {
  const patch = getFighterMoveOverrides(fighterId, moveId);
  if (!patch) return base;
  const { spawnsProjectile: _p, projectileDamage: _pd, projectileKnockback: _pk, ...framePatch } = patch;
  return { ...base, ...framePatch };
}

export function fighterSpawnsProjectileOnMove(fighterId: string, moveId: string): boolean {
  return !!getFighterMoveOverrides(fighterId, moveId)?.spawnsProjectile;
}

export function getProjectileStatsForMove(
  fighterId: string,
  moveId: string,
): { damage: number; knockback: number } | null {
  const patch = getFighterMoveOverrides(fighterId, moveId);
  if (!patch?.spawnsProjectile) return null;
  const base = getCatalogMove(moveId);
  return {
    damage: patch.projectileDamage ?? base?.damage ?? 6,
    knockback: patch.projectileKnockback ?? base?.baseKnockback ?? 7,
  };
}

/** @deprecated use applyFighterMoveOverrides */
export const applyProductionMoveOverrides = applyFighterMoveOverrides;
