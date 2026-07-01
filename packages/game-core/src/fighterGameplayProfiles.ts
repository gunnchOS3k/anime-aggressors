import type { DefaultFighterId, DefaultFighterProfile } from "./defaultFighters.js";
import { DEFAULT_FIGHTERS, getDefaultFighterProfile } from "./defaultFighters.js";
import { buildCreatedFighter } from "./createdFighter.js";
import type { CreatedFighter } from "./createdFighter.js";

/** Milestone 4 production-validated fighters (full balance + CPU/training coverage). */
export const PRODUCTION_FIGHTER_IDS = [
  "ember-vale",
  "rook-ironside",
  "juno-spark",
  "kaia-windrow",
] as const satisfies readonly DefaultFighterId[];

/** Selectable preview fighters (mechanically valid, balance-pending). */
export const PREVIEW_FIGHTER_IDS = [
  "nix-calder",
  "orion-vell",
  "vesper-nyx",
] as const satisfies readonly DefaultFighterId[];

export type ProductionFighterId = (typeof PRODUCTION_FIGHTER_IDS)[number];
export type PreviewFighterId = (typeof PREVIEW_FIGHTER_IDS)[number];

export type FighterRosterStatus = "production" | "preview";

export type FighterGameplayProfile = {
  fighterId: DefaultFighterId;
  status: FighterRosterStatus;
  archetype: string;
  weight: number;
  runSpeedMult: number;
  airSpeedMult: number;
  fallSpeedMult: number;
  maxJumps: number;
  jumpVelocityMult: number;
  recoveryUpBoost: number;
  shieldHealthMult: number;
  damageMult: number;
  knockbackTakenMult: number;
};

const GAMEPLAY: Record<DefaultFighterId, Omit<FighterGameplayProfile, "fighterId" | "archetype">> = {
  "ember-vale": {
    status: "production",
    weight: 100,
    runSpeedMult: 105,
    airSpeedMult: 102,
    fallSpeedMult: 100,
    maxJumps: 2,
    jumpVelocityMult: 100,
    recoveryUpBoost: 108,
    shieldHealthMult: 100,
    damageMult: 100,
    knockbackTakenMult: 100,
  },
  "rook-ironside": {
    status: "production",
    weight: 125,
    runSpeedMult: 85,
    airSpeedMult: 88,
    fallSpeedMult: 108,
    maxJumps: 2,
    jumpVelocityMult: 92,
    recoveryUpBoost: 95,
    shieldHealthMult: 115,
    damageMult: 118,
    knockbackTakenMult: 88,
  },
  "juno-spark": {
    status: "production",
    weight: 82,
    runSpeedMult: 118,
    airSpeedMult: 122,
    fallSpeedMult: 102,
    maxJumps: 2,
    jumpVelocityMult: 108,
    recoveryUpBoost: 105,
    shieldHealthMult: 92,
    damageMult: 92,
    knockbackTakenMult: 112,
  },
  "kaia-windrow": {
    status: "production",
    weight: 96,
    runSpeedMult: 98,
    airSpeedMult: 112,
    fallSpeedMult: 96,
    maxJumps: 2,
    jumpVelocityMult: 104,
    recoveryUpBoost: 110,
    shieldHealthMult: 98,
    damageMult: 96,
    knockbackTakenMult: 104,
  },
  "nix-calder": {
    status: "preview",
    weight: 118,
    runSpeedMult: 90,
    airSpeedMult: 90,
    fallSpeedMult: 105,
    maxJumps: 2,
    jumpVelocityMult: 95,
    recoveryUpBoost: 98,
    shieldHealthMult: 110,
    damageMult: 105,
    knockbackTakenMult: 90,
  },
  "orion-vell": {
    status: "preview",
    weight: 100,
    runSpeedMult: 100,
    airSpeedMult: 100,
    fallSpeedMult: 100,
    maxJumps: 2,
    jumpVelocityMult: 100,
    recoveryUpBoost: 100,
    shieldHealthMult: 100,
    damageMult: 100,
    knockbackTakenMult: 100,
  },
  "vesper-nyx": {
    status: "preview",
    weight: 88,
    runSpeedMult: 95,
    airSpeedMult: 98,
    fallSpeedMult: 96,
    maxJumps: 2,
    jumpVelocityMult: 98,
    recoveryUpBoost: 102,
    shieldHealthMult: 95,
    damageMult: 94,
    knockbackTakenMult: 106,
  },
};

export function isProductionFighterId(id: string): id is ProductionFighterId {
  return (PRODUCTION_FIGHTER_IDS as readonly string[]).includes(id);
}

export function isPreviewFighterId(id: string): id is PreviewFighterId {
  return (PREVIEW_FIGHTER_IDS as readonly string[]).includes(id);
}

export function getFighterGameplayProfile(fighterId: string): FighterGameplayProfile | undefined {
  const normalized = fighterId.replace(/^created:/, "") as DefaultFighterId;
  const base = GAMEPLAY[normalized];
  const def = getDefaultFighterProfile(normalized);
  if (!base || !def) return undefined;
  return { fighterId: normalized, archetype: def.archetype, ...base };
}

export function getProductionFighters(): DefaultFighterProfile[] {
  return PRODUCTION_FIGHTER_IDS.map((id) => getDefaultFighterProfile(id)!);
}

export function getPreviewFighters(): DefaultFighterProfile[] {
  return PREVIEW_FIGHTER_IDS.map((id) => getDefaultFighterProfile(id)!);
}

export function getPlayableRoster(): DefaultFighterProfile[] {
  return [...DEFAULT_FIGHTERS];
}

export function getProductionCreatedFighters(): CreatedFighter[] {
  return getProductionFighters().map((f) =>
    buildCreatedFighter({ id: f.id, name: f.name, size: f.size, color: f.color }),
  );
}

export function getPlayableCreatedFighters(): CreatedFighter[] {
  return DEFAULT_FIGHTERS.map((f) =>
    buildCreatedFighter({ id: f.id, name: f.name, size: f.size, color: f.color }),
  );
}

export function uniqueProductionArchetypes(): string[] {
  return [...new Set(getProductionFighters().map((f) => f.archetype))];
}
