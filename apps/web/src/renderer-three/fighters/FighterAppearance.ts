import type { CreatedFighter, FighterColor, FighterSize } from "@anime-aggressors/game-core";
import { DEFAULT_FIGHTER_ROSTER, ELEMENTS, getSizeStats } from "@anime-aggressors/game-core";
import type { PlayerState } from "@anime-aggressors/game-core";
import { getElementVfxStyle, hexForElement, type ElementVfxStyle } from "./FighterEffectsStyle.ts";

export type SilhouetteKind = "angular" | "sleek" | "lean" | "heavy";

export type FighterAppearance = {
  name: string;
  size: FighterSize;
  color: FighterColor;
  primaryHex: number;
  accentHex: number;
  darkHex: number;
  silhouette: SilhouetteKind;
  vfx: ElementVfxStyle;
  scale: number;
  accessory: "blade" | "scarf" | "wings" | "cape" | "none";
};

const ARCHETYPE_SILHOUETTE: Record<string, SilhouetteKind> = {
  "default-0": "angular",
  "default-1": "sleek",
  "default-2": "lean",
  "default-3": "heavy",
};

const ARCHETYPE_ACCESSORY: Record<string, FighterAppearance["accessory"]> = {
  "default-0": "blade",
  "default-1": "scarf",
  "default-2": "wings",
  "default-3": "cape",
};

const SIZE_SCALE: Record<FighterSize, number> = {
  small: 0.88,
  medium: 1.0,
  large: 1.18,
};

function darken(hex: number, amount = 0.35): number {
  const r = ((hex >> 16) & 0xff) * (1 - amount);
  const g = ((hex >> 8) & 0xff) * (1 - amount);
  const b = (hex & 0xff) * (1 - amount);
  return (Math.floor(r) << 16) | (Math.floor(g) << 8) | Math.floor(b);
}

function accentize(hex: number): number {
  const r = Math.min(255, ((hex >> 16) & 0xff) + 40);
  const g = Math.min(255, ((hex >> 8) & 0xff) + 40);
  const b = Math.min(255, (hex & 0xff) + 40);
  return (r << 16) | (g << 8) | b;
}

export function silhouetteForFighterId(id: string): SilhouetteKind {
  return ARCHETYPE_SILHOUETTE[id] ?? "angular";
}

export function resolveFighterAppearanceFromPlayer(player: PlayerState): FighterAppearance {
  return resolveFighterAppearance({
    id: player.characterId.replace("created:", ""),
    name: player.fighterName,
    size: player.fighterSize ?? "medium",
    color: player.fighterColor ?? "red",
  });
}

export function resolveFighterAppearance(fighter: Pick<CreatedFighter, "id" | "name" | "size" | "color">): FighterAppearance {
  const roster = DEFAULT_FIGHTER_ROSTER.find((f) => f.id === fighter.id);
  const color = fighter.color;
  const primary = hexForElement(color);
  const sizeStats = getSizeStats(fighter.size);
  return {
    name: fighter.name,
    size: fighter.size,
    color,
    primaryHex: primary,
    accentHex: accentize(primary),
    darkHex: darken(primary, 0.45),
    silhouette: roster ? silhouetteForFighterId(fighter.id) : sizeSilhouette(fighter.size),
    vfx: getElementVfxStyle(color),
    scale: SIZE_SCALE[fighter.size] * sizeStats.hurtboxScale,
    accessory: roster ? (ARCHETYPE_ACCESSORY[fighter.id] ?? "none") : accessoryForColor(color),
  };
}

function sizeSilhouette(size: FighterSize): SilhouetteKind {
  if (size === "small") return "lean";
  if (size === "large") return "heavy";
  return "angular";
}

function accessoryForColor(color: FighterColor): FighterAppearance["accessory"] {
  const map: Partial<Record<FighterColor, FighterAppearance["accessory"]>> = {
    red: "blade",
    blue: "scarf",
    yellow: "wings",
    violet: "cape",
    orange: "blade",
    green: "wings",
    indigo: "cape",
  };
  return map[color] ?? "none";
}

export function elementLabel(color: FighterColor): string {
  return ELEMENTS[color].name;
}
