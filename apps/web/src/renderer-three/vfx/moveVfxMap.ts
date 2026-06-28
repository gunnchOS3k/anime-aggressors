import type { FighterColor } from "@anime-aggressors/game-core";
import { getElementVfxStyle } from "../fighters/FighterEffectsStyle.ts";

export type VfxColorSet = {
  trail: number;
  hit: number;
  hitHeavy: number;
  aura: number;
};

const STYLE_TO_COLOR: Record<string, FighterColor> = {
  ember: "red",
  rook: "orange",
  juno: "yellow",
  kaia: "green",
  nix: "blue",
  orion: "indigo",
  vesper: "violet",
};

export function getVfxColorsForStyle(vfxStyle: string): VfxColorSet {
  const color = STYLE_TO_COLOR[vfxStyle] ?? "red";
  const element = getElementVfxStyle(color);
  return {
    trail: element.dash,
    hit: element.hitSpark,
    hitHeavy: element.hitSparkHeavy,
    aura: element.aura,
  };
}

export function getTrailColorForStyle(vfxStyle: string): number {
  return getVfxColorsForStyle(vfxStyle).trail;
}

export function getHitColorForStyle(vfxStyle: string): number {
  return getVfxColorsForStyle(vfxStyle).hit;
}

export const MOVE_VFX_STYLES = Object.keys(STYLE_TO_COLOR);
