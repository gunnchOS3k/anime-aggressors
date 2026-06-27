import type { CreatedFighter } from "./createdFighter.js";
import { buildCreatedFighter } from "./createdFighter.js";
import type { FighterColor } from "./elements.js";
import type { FighterSize } from "./sizeClasses.js";

export type DefaultFighterId =
  | "ember-vale"
  | "rook-ironside"
  | "juno-spark"
  | "kaia-windrow"
  | "nix-calder"
  | "orion-vell"
  | "vesper-nyx";

export type PreviewAnimationId =
  | "flame-gauntlet-ignite"
  | "impact-stomp"
  | "volt-afterimage"
  | "gale-hover"
  | "frost-mantle"
  | "gravity-orbit"
  | "void-afterimage";

export type DefaultFighterProfile = {
  id: DefaultFighterId;
  name: string;
  size: FighterSize;
  color: FighterColor;
  elementName: string;
  archetype: string;
  shortTagline: string;
  previewAnimation: PreviewAnimationId;
  signatureMoveName: string;
  visualStyleId: string;
};

export type DefaultFighterPreset = Pick<CreatedFighter, "id" | "name" | "size" | "color">;

/** Original ROYGBIV default roster — one fighter per element. */
export const DEFAULT_FIGHTERS: DefaultFighterProfile[] = [
  {
    id: "ember-vale",
    name: "Ember Vale",
    size: "medium",
    color: "red",
    elementName: "Flame",
    archetype: "Rushdown Striker",
    shortTagline: "Ignites close-range pressure.",
    previewAnimation: "flame-gauntlet-ignite",
    signatureMoveName: "Cinder Rush",
    visualStyleId: "ember",
  },
  {
    id: "rook-ironside",
    name: "Rook Ironside",
    size: "large",
    color: "orange",
    elementName: "Impact",
    archetype: "Armored Bruiser",
    shortTagline: "Turns every hit into a quake.",
    previewAnimation: "impact-stomp",
    signatureMoveName: "Faultline Breaker",
    visualStyleId: "rook",
  },
  {
    id: "juno-spark",
    name: "Juno Spark",
    size: "small",
    color: "yellow",
    elementName: "Volt",
    archetype: "Speed Confirm",
    shortTagline: "Dashes in before sparks fade.",
    previewAnimation: "volt-afterimage",
    signatureMoveName: "Flash Circuit",
    visualStyleId: "juno",
  },
  {
    id: "kaia-windrow",
    name: "Kaia Windrow",
    size: "medium",
    color: "green",
    elementName: "Gale",
    archetype: "Aerial Spacer",
    shortTagline: "Controls the air around her.",
    previewAnimation: "gale-hover",
    signatureMoveName: "Spiral Current",
    visualStyleId: "kaia",
  },
  {
    id: "nix-calder",
    name: "Nix Calder",
    size: "large",
    color: "blue",
    elementName: "Frost",
    archetype: "Control Tank",
    shortTagline: "Freezes the pace of battle.",
    previewAnimation: "frost-mantle",
    signatureMoveName: "Glacier Lock",
    visualStyleId: "nix",
  },
  {
    id: "orion-vell",
    name: "Orion Vell",
    size: "medium",
    color: "indigo",
    elementName: "Gravity",
    archetype: "Combo Control",
    shortTagline: "Pulls rivals into his rhythm.",
    previewAnimation: "gravity-orbit",
    signatureMoveName: "Orbit Collapse",
    visualStyleId: "orion",
  },
  {
    id: "vesper-nyx",
    name: "Vesper Nyx",
    size: "small",
    color: "violet",
    elementName: "Void",
    archetype: "Phase Trickster",
    shortTagline: "Vanishes where the hit should land.",
    previewAnimation: "void-afterimage",
    signatureMoveName: "Null Step",
    visualStyleId: "vesper",
  },
];

/** @deprecated use DEFAULT_FIGHTERS */
export const DEFAULT_FIGHTER_ROSTER: DefaultFighterPreset[] = DEFAULT_FIGHTERS.map((f) => ({
  id: f.id,
  name: f.name,
  size: f.size,
  color: f.color,
}));

const LEGACY_ID_MAP: Record<string, DefaultFighterId> = {
  "default-0": "ember-vale",
  "default-1": "rook-ironside",
  "default-2": "juno-spark",
  "default-3": "kaia-windrow",
};

export function normalizeDefaultFighterId(id: string): string {
  return LEGACY_ID_MAP[id] ?? id;
}

export function isDefaultFighterId(id: string): id is DefaultFighterId {
  const normalized = normalizeDefaultFighterId(id);
  return DEFAULT_FIGHTERS.some((f) => f.id === normalized);
}

export function getDefaultFighterProfile(id: string): DefaultFighterProfile | undefined {
  const normalized = normalizeDefaultFighterId(id);
  return DEFAULT_FIGHTERS.find((f) => f.id === normalized);
}

export function getDefaultFighterPreset(playerIndex: number): DefaultFighterPreset {
  const fighter = DEFAULT_FIGHTERS[playerIndex] ?? DEFAULT_FIGHTERS[0];
  return { id: fighter.id, name: fighter.name, size: fighter.size, color: fighter.color };
}

export function getAllDefaultCreatedFighters(): CreatedFighter[] {
  return DEFAULT_FIGHTERS.map((f) =>
    buildCreatedFighter({ id: f.id, name: f.name, size: f.size, color: f.color }),
  );
}

export function getRoygbivColors(): FighterColor[] {
  return DEFAULT_FIGHTERS.map((f) => f.color);
}
