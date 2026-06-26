export type FighterSize = "small" | "medium" | "large";

export type SizeStats = {
  label: string;
  speedMultiplier: number;
  jumpMultiplier: number;
  damageMultiplier: number;
  knockbackTakenMultiplier: number;
  weight: number;
  hurtboxScale: number;
};

export const SIZE_STATS: Record<FighterSize, SizeStats> = {
  small: {
    label: "Small",
    speedMultiplier: 1.12,
    jumpMultiplier: 1.08,
    damageMultiplier: 0.88,
    knockbackTakenMultiplier: 1.12,
    weight: 0.85,
    hurtboxScale: 0.85,
  },
  medium: {
    label: "Medium",
    speedMultiplier: 1.0,
    jumpMultiplier: 1.0,
    damageMultiplier: 1.0,
    knockbackTakenMultiplier: 1.0,
    weight: 1.0,
    hurtboxScale: 1.0,
  },
  large: {
    label: "Large",
    speedMultiplier: 0.88,
    jumpMultiplier: 0.92,
    damageMultiplier: 1.15,
    knockbackTakenMultiplier: 0.88,
    weight: 1.2,
    hurtboxScale: 1.18,
  },
};

export function getSizeStats(size: FighterSize): SizeStats {
  return SIZE_STATS[size];
}

export function scaleBySize(value: number, multiplier: number): number {
  return Math.floor(value * multiplier);
}
