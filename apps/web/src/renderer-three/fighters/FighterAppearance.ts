import type { CreatedFighter, FighterColor, FighterSize } from "@anime-aggressors/game-core";
import {
  DEFAULT_FIGHTERS,
  ELEMENTS,
  getDefaultFighterProfile,
  getSizeStats,
  normalizeDefaultFighterId,
} from "@anime-aggressors/game-core";
import type { PlayerState } from "@anime-aggressors/game-core";
import { getElementVfxStyle, hexForElement, type ElementVfxStyle } from "./FighterEffectsStyle.ts";
import {
  getDefaultFighterAppearance,
  type DefaultFighterAppearance,
  type BodyShape,
} from "./defaultFighterAppearances.ts";

export type SilhouetteKind = "angular" | "sleek" | "lean" | "heavy";

export type FighterVisualParts = DefaultFighterAppearance["silhouetteParts"];

export type FighterAppearance = {
  name: string;
  size: FighterSize;
  color: FighterColor;
  primaryHex: number;
  accentHex: number;
  darkHex: number;
  silhouette: SilhouetteKind;
  bodyShape: BodyShape;
  vfx: ElementVfxStyle;
  scale: number;
  accessory: "blade" | "scarf" | "wings" | "cape" | "none";
  parts: FighterVisualParts;
  visualStyleId?: string;
};

const BODY_SHAPE_SILHOUETTE: Record<BodyShape, SilhouetteKind> = {
  compact: "lean",
  athletic: "angular",
  broad: "heavy",
};

const LEGACY_SILHOUETTE: Record<string, SilhouetteKind> = {
  "ember-vale": "angular",
  "rook-ironside": "heavy",
  "juno-spark": "lean",
  "kaia-windrow": "sleek",
  "nix-calder": "heavy",
  "orion-vell": "sleek",
  "vesper-nyx": "lean",
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

function parseHex(hex: string): number {
  return Number.parseInt(hex.replace("#", ""), 16);
}

export function silhouetteForFighterId(id: string): SilhouetteKind {
  const normalized = normalizeDefaultFighterId(id);
  return LEGACY_SILHOUETTE[normalized] ?? "angular";
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
  const normalizedId = normalizeDefaultFighterId(fighter.id);
  const profile = getDefaultFighterProfile(normalizedId);
  const visual = getDefaultFighterAppearance(normalizedId);
  const color = fighter.color;
  const primary = visual ? parseHex(visual.secondaryColor) : hexForElement(color);
  const sizeStats = getSizeStats(fighter.size);
  const bodyShape = visual?.bodyShape ?? sizeBodyShape(fighter.size);

  return {
    name: fighter.name,
    size: fighter.size,
    color,
    primaryHex: primary,
    accentHex: visual ? parseHex(visual.accentColor) : accentize(primary),
    darkHex: visual ? parseHex(visual.primaryColor) : darken(primary, 0.45),
    silhouette: visual ? BODY_SHAPE_SILHOUETTE[visual.bodyShape] : sizeSilhouette(fighter.size),
    bodyShape,
    vfx: getElementVfxStyle(color),
    scale: SIZE_SCALE[fighter.size] * sizeStats.hurtboxScale,
    accessory: visual ? accessoryFromParts(visual.silhouetteParts) : accessoryForColor(color),
    parts: visual?.silhouetteParts ?? partsForColor(color),
    visualStyleId: profile?.visualStyleId,
  };
}

function sizeBodyShape(size: FighterSize): BodyShape {
  if (size === "small") return "compact";
  if (size === "large") return "broad";
  return "athletic";
}

function accessoryFromParts(parts: FighterVisualParts): FighterAppearance["accessory"] {
  if (parts.cape) return "cape";
  if (parts.wingSleeves) return "wings";
  if (parts.scarf) return "scarf";
  if (parts.gauntlets || parts.jacket) return "blade";
  return "none";
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

function partsForColor(color: FighterColor): FighterVisualParts {
  const map: Partial<Record<FighterColor, FighterVisualParts>> = {
    red: { gauntlets: "flame", jacket: "short" },
    orange: { shoulderArmor: "block", heavyBoots: "heavy" },
    yellow: { scarf: "lightning", hair: "tufts" },
    green: { wingSleeves: "flow", scarf: "sash" },
    blue: { mantle: "ice", gauntlets: "heavy" },
    indigo: { jacket: "long-coat", floatingBits: "stones" },
    violet: { hood: "collar", cape: "asymmetric" },
  };
  return map[color] ?? {};
}

export function elementLabel(color: FighterColor): string {
  return ELEMENTS[color].name;
}

export function listDefaultFighterProfiles() {
  return DEFAULT_FIGHTERS;
}
