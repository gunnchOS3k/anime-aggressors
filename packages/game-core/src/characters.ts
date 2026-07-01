import type { PlayerState } from "./types.js";
import { getDefaultFighterProfile } from "./defaultFighters.js";
import { getFighterGameplayProfile, isProductionFighterId } from "./fighterGameplayProfiles.js";

export type CharacterDef = {
  id: string;
  name: string;
  tagline: string;
  maxJumps: number;
  runSpeedMult: number;
  weight: number;
  attackDamage: number;
  specialDamage: number;
  color: string;
  airSpeedMult?: number;
  fallSpeedMult?: number;
  jumpVelocityMult?: number;
};

const ACCENT_HEX: Record<string, string> = {
  "ember-vale": "#e85a4f",
  "rook-ironside": "#e07a3a",
  "juno-spark": "#f5d547",
  "kaia-windrow": "#5ecf8f",
  "nix-calder": "#4a9fd4",
  "orion-vell": "#6b5ce6",
  "vesper-nyx": "#9b6cf0",
};

/** Legacy test characters. */
const CHARACTERS: Record<string, CharacterDef> = {
  ember: {
    id: "ember",
    name: "Ember Vale",
    tagline: "Rising flame striker",
    maxJumps: 2,
    runSpeedMult: 110,
    weight: 100,
    attackDamage: 8,
    specialDamage: 14,
    color: "#ff6b35",
  },
  tide: {
    id: "tide",
    name: "Tide Kuro",
    tagline: "Flow-state defender",
    maxJumps: 2,
    runSpeedMult: 95,
    weight: 115,
    attackDamage: 7,
    specialDamage: 16,
    color: "#4ecdc4",
  },
};

function fromGameplayProfile(id: string): CharacterDef | undefined {
  const profile = getFighterGameplayProfile(id);
  const def = getDefaultFighterProfile(id);
  if (!profile || !def) return undefined;
  return {
    id: profile.fighterId,
    name: def.name,
    tagline: def.shortTagline,
    maxJumps: profile.maxJumps,
    runSpeedMult: profile.runSpeedMult,
    weight: profile.weight,
    attackDamage: Math.round(6 * (profile.damageMult / 100)),
    specialDamage: Math.round(12 * (profile.damageMult / 100)),
    color: ACCENT_HEX[profile.fighterId] ?? "#ffffff",
    airSpeedMult: profile.airSpeedMult,
    fallSpeedMult: profile.fallSpeedMult,
    jumpVelocityMult: profile.jumpVelocityMult,
  };
}

export function getCharacter(id: string): CharacterDef {
  const tuned = fromGameplayProfile(id);
  if (tuned) return tuned;
  return CHARACTERS[id] ?? CHARACTERS.ember;
}

export function getCharacterForPlayer(player: Pick<PlayerState, "characterId" | "fighterSize">): CharacterDef {
  const id = player.characterId;
  if (CHARACTERS[id]) return CHARACTERS[id]!;
  const tuned = fromGameplayProfile(id);
  if (tuned) return tuned;
  const base = CHARACTERS.ember!;
  const size = player.fighterSize ?? "medium";
  const speedMult = size === "small" ? 112 : size === "large" ? 88 : 100;
  const weight = size === "small" ? 85 : size === "large" ? 120 : 100;
  return {
    ...base,
    id,
    maxJumps: 2,
    runSpeedMult: speedMult,
    weight,
  };
}

export function listCharacters(): CharacterDef[] {
  return Object.values(CHARACTERS);
}

export { isProductionFighterId };
