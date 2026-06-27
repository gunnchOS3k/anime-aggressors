import type { FighterColor } from "@anime-aggressors/game-core";
import { ELEMENTS } from "@anime-aggressors/game-core";

export type TrailStyle =
  | "flameArc"
  | "waterRibbon"
  | "windSlash"
  | "electricJag"
  | "frostShard"
  | "gravityRing"
  | "voidSmear"
  | "impactBurst";

export type ElementVfxStyle = {
  trail: TrailStyle;
  hitSpark: number;
  hitSparkHeavy: number;
  aura: number;
  dash: number;
  shield: number;
  ko: number;
};

const ELEMENT_VFX: Record<FighterColor, ElementVfxStyle> = {
  red: {
    trail: "flameArc",
    hitSpark: 0xff6622,
    hitSparkHeavy: 0xffaa33,
    aura: 0xff4422,
    dash: 0xff8844,
    shield: 0xff5533,
    ko: 0xff2200,
  },
  orange: {
    trail: "impactBurst",
    hitSpark: 0xff9933,
    hitSparkHeavy: 0xffcc55,
    aura: 0xff7700,
    dash: 0xffaa44,
    shield: 0xff8844,
    ko: 0xff5500,
  },
  yellow: {
    trail: "electricJag",
    hitSpark: 0xffee44,
    hitSparkHeavy: 0xffff88,
    aura: 0xffdd22,
    dash: 0xffff66,
    shield: 0xffee88,
    ko: 0xffcc00,
  },
  green: {
    trail: "windSlash",
    hitSpark: 0x66ff88,
    hitSparkHeavy: 0xaaffcc,
    aura: 0x44dd66,
    dash: 0x88ffaa,
    shield: 0x66cc88,
    ko: 0x22aa44,
  },
  blue: {
    trail: "frostShard",
    hitSpark: 0x66ccff,
    hitSparkHeavy: 0xaaeeff,
    aura: 0x4499ff,
    dash: 0x88ddff,
    shield: 0x5599ff,
    ko: 0x2288ff,
  },
  indigo: {
    trail: "gravityRing",
    hitSpark: 0x9966ff,
    hitSparkHeavy: 0xcc99ff,
    aura: 0x7744cc,
    dash: 0xaa88ff,
    shield: 0x8866dd,
    ko: 0x5522aa,
  },
  violet: {
    trail: "voidSmear",
    hitSpark: 0xcc66ff,
    hitSparkHeavy: 0xee99ff,
    aura: 0x9933cc,
    dash: 0xbb66ee,
    shield: 0xaa44cc,
    ko: 0x7700aa,
  },
};

export function getElementVfxStyle(color: FighterColor): ElementVfxStyle {
  return ELEMENT_VFX[color];
}

export function getElementTrailStyle(color: FighterColor): TrailStyle {
  return ELEMENT_VFX[color].trail;
}

export function hexForElement(color: FighterColor): number {
  const hex = ELEMENTS[color].hexColor;
  return Number.parseInt(hex.slice(1), 16);
}
