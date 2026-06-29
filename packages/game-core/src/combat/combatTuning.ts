export const HITLAG_DEFAULTS = {
  light: 3,
  medium: 5,
  heavy: 8,
  launch: 10,
  super: 14,
  beamClash: 18,
} as const;

export type HitStrength = keyof typeof HITLAG_DEFAULTS;

export const HITLAG_FRAMES = HITLAG_DEFAULTS;

export const KNOCKBACK_TUNING = {
  baseWeight: 100,
  damageGrowthFactor: 0.14,
  launchAngleRadDefault: -0.65,
  superMultiplier: 1.42,
  heavyMultiplier: 1.22,
  mediumMultiplier: 1.05,
  lightMultiplier: 0.8,
} as const;

export function classifyHitStrength(
  damage: number,
  moveId: string,
): HitStrength {
  if (moveId.includes("super")) return "super";
  if (moveId.includes("launch") || moveId.includes("upper")) return "launch";
  if (damage >= 18) return "heavy";
  if (damage >= 10) return "medium";
  return "light";
}

export function cameraImpulseForStrength(strength: HitStrength): "lightHit" | "heavyHit" | "launch" | "ko" | "super" | "beamClash" {
  if (strength === "super") return "super";
  if (strength === "heavy" || strength === "launch") return "heavyHit";
  if (strength === "medium") return "heavyHit";
  return "lightHit";
}
