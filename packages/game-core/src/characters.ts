import type { PlayerState } from "./types.js";

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
};

/** Original characters — no third-party IP. */
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

export function getCharacter(id: string): CharacterDef {
  return CHARACTERS[id] ?? CHARACTERS.ember;
}

/** Resolve character stats for legacy ids and created fighters. */
export function getCharacterForPlayer(player: Pick<PlayerState, "characterId" | "fighterSize">): CharacterDef {
  const id = player.characterId;
  if (CHARACTERS[id]) return CHARACTERS[id]!;
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
