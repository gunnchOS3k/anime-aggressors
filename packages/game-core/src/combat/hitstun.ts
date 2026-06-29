import { HITSTUN_BASE } from "../constants.js";
import type { HitStrength } from "./combatTuning.js";

export function computeHitstun(strength: HitStrength, victimDamagePercent: number): number {
  const base =
    strength === "super"
      ? HITSTUN_BASE * 3
      : strength === "heavy" || strength === "launch"
        ? HITSTUN_BASE * 2
        : strength === "medium"
          ? HITSTUN_BASE + 4
          : HITSTUN_BASE;
  return base + Math.floor(victimDamagePercent / 12);
}

export function isLaunched(strength: HitStrength, knockbackMagnitude: number): boolean {
  return strength === "launch" || strength === "super" || strength === "heavy" || knockbackMagnitude >= 14;
}
