import type { CreatedFighter } from "./createdFighter.js";
import { buildCreatedFighter } from "./createdFighter.js";

export type DefaultFighterPreset = Pick<CreatedFighter, "id" | "name" | "size" | "color">;

/** Original default roster — distinct silhouettes and element identities. */
export const DEFAULT_FIGHTER_ROSTER: DefaultFighterPreset[] = [
  { id: "default-0", name: "Ember Vale", size: "medium", color: "red" },
  { id: "default-1", name: "Tide Kuro", size: "medium", color: "blue" },
  { id: "default-2", name: "Zeph Ray", size: "small", color: "yellow" },
  { id: "default-3", name: "Nova Grimm", size: "large", color: "violet" },
];

export function getDefaultFighterPreset(playerIndex: number): DefaultFighterPreset {
  return DEFAULT_FIGHTER_ROSTER[playerIndex] ?? DEFAULT_FIGHTER_ROSTER[0];
}
