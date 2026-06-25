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

export function listCharacters(): CharacterDef[] {
  return Object.values(CHARACTERS);
}
