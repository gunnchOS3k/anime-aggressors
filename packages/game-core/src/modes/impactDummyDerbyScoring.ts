import type { DerbyGrade, ImpactDummyDerbyState } from "./impactDummyDerbyTypes.js";
import { FP_SCALE } from "../constants.js";

export function distanceDisplayUnits(fpDistance: number): number {
  return Math.floor(fpDistance / FP_SCALE);
}

export function computeDerbyScore(state: ImpactDummyDerbyState): number {
  const distUnits = distanceDisplayUnits(state.finalDistance);
  const timingBonus =
    state.finalLaunchFramesRemaining > 0
      ? Math.floor(state.finalLaunchFramesRemaining / 6)
      : 0;
  return (
    distUnits * 10 +
    Math.floor(state.dummy.damage * 20) +
    Math.floor(state.finalLaunchSpeed * 5) +
    state.bestCombo * 50 +
    timingBonus
  );
}

export function gradeFromScore(score: number): DerbyGrade {
  if (score >= 6000) return "SS";
  if (score >= 3500) return "S";
  if (score >= 2000) return "A";
  if (score >= 1000) return "B";
  if (score >= 500) return "C";
  return "D";
}

export function launchAngleDeg(vx: number, vy: number): number {
  if (vx === 0 && vy === 0) return 0;
  const rad = Math.atan2(-vy, vx);
  return Math.round((rad * 180) / Math.PI);
}

export function syncLegacyScoreFields(state: ImpactDummyDerbyState): void {
  state.distance = state.finalDistance;
  state.launchSpeed = state.finalLaunchSpeed;
  state.bestScore = state.personalBest;
  state.kineticBatAvailable = state.kineticBat.available;
  state.kineticBatEquipped = state.kineticBat.equipped;
}
