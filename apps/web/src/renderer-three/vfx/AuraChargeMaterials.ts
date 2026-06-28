import type { FighterColor } from "@anime-aggressors/game-core";

export type ElementAuraVisualStyle = {
  element: FighterColor;
  shape: "flameTongues" | "shockPlates" | "electricArcs" | "windRibbons" | "frostShards" | "gravityOrbit" | "voidSmears";
  particle: "embers" | "chunks" | "lightning" | "leaves" | "snow" | "stones" | "motes";
  motion: "flickerUp" | "pulseOut" | "snapBlink" | "spiral" | "slowExpand" | "orbitIn" | "phaseFlicker";
  ringColor: number;
  particleColor: number;
  glowColor: number;
};

export const ROYGBIV_AURA_STYLES: Record<FighterColor, ElementAuraVisualStyle> = {
  red: {
    element: "red",
    shape: "flameTongues",
    particle: "embers",
    motion: "flickerUp",
    ringColor: 0xff4422,
    particleColor: 0xffaa44,
    glowColor: 0xff6633,
  },
  orange: {
    element: "orange",
    shape: "shockPlates",
    particle: "chunks",
    motion: "pulseOut",
    ringColor: 0xff8844,
    particleColor: 0xffcc66,
    glowColor: 0xffaa55,
  },
  yellow: {
    element: "yellow",
    shape: "electricArcs",
    particle: "lightning",
    motion: "snapBlink",
    ringColor: 0xffee44,
    particleColor: 0xffffaa,
    glowColor: 0xffdd22,
  },
  green: {
    element: "green",
    shape: "windRibbons",
    particle: "leaves",
    motion: "spiral",
    ringColor: 0x44ff88,
    particleColor: 0x88ffcc,
    glowColor: 0x66ee99,
  },
  blue: {
    element: "blue",
    shape: "frostShards",
    particle: "snow",
    motion: "slowExpand",
    ringColor: 0x66ccff,
    particleColor: 0xcceeff,
    glowColor: 0x88bbff,
  },
  indigo: {
    element: "indigo",
    shape: "gravityOrbit",
    particle: "stones",
    motion: "orbitIn",
    ringColor: 0x6677cc,
    particleColor: 0x99aaff,
    glowColor: 0x7788dd,
  },
  violet: {
    element: "violet",
    shape: "voidSmears",
    particle: "motes",
    motion: "phaseFlicker",
    ringColor: 0xaa44ff,
    particleColor: 0xdd88ff,
    glowColor: 0xcc66ff,
  },
};

export function getAuraStyleForColor(color: FighterColor): ElementAuraVisualStyle {
  return ROYGBIV_AURA_STYLES[color];
}

export function auraOpacityForLevel(level: number): number {
  return 0.22 + level * 0.18;
}

export function auraScaleForLevel(level: number): number {
  return 1 + level * 0.22;
}
