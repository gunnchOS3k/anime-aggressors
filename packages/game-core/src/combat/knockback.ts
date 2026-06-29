import { FP_SCALE } from "../constants.js";
import { KNOCKBACK_TUNING, type HitStrength } from "./combatTuning.js";

export type KnockbackResult = {
  vx: number;
  vy: number;
  magnitude: number;
};

export function computeKnockback(args: {
  moveDamage: number;
  baseKnockback: number;
  knockbackGrowth: number;
  victimDamagePercent: number;
  victimWeight: number;
  launchRatio: number;
  hitStrength: HitStrength;
  angleDeg: number;
}): KnockbackResult {
  const {
    moveDamage,
    baseKnockback,
    knockbackGrowth,
    victimDamagePercent,
    victimWeight,
    launchRatio,
    hitStrength,
    angleDeg,
  } = args;

  const weightFactor = KNOCKBACK_TUNING.baseWeight / Math.max(60, victimWeight);
  const growth = baseKnockback + knockbackGrowth * victimDamagePercent * KNOCKBACK_TUNING.damageGrowthFactor;
  const strengthMult =
    hitStrength === "super"
      ? KNOCKBACK_TUNING.superMultiplier
      : hitStrength === "heavy" || hitStrength === "launch"
        ? KNOCKBACK_TUNING.heavyMultiplier
        : hitStrength === "medium"
          ? KNOCKBACK_TUNING.mediumMultiplier
          : KNOCKBACK_TUNING.lightMultiplier;

  const magnitude = Math.max(1, (growth + moveDamage * 0.4) * strengthMult * weightFactor * launchRatio);
  const rad = (angleDeg * Math.PI) / 180;
  const vx = Math.cos(rad) * magnitude * FP_SCALE * 0.08;
  const vy = Math.sin(rad) * magnitude * FP_SCALE * 0.08;

  return { vx, vy, magnitude };
}
