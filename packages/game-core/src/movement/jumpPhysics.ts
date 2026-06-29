import type { PlayerState } from "../types.js";
import { MOVEMENT_BASE, movementTuningForSize, scaledMovementValue } from "./movementTuning.js";
import { getPlayerSizeStats } from "../fighterCreation.js";

export function computeJumpVelocity(player: PlayerState): number {
  const tuning = movementTuningForSize(player.fighterSize ?? "medium");
  const stats = getPlayerSizeStats(player);
  const base = scaledMovementValue(MOVEMENT_BASE.jumpVelocity, tuning.jumpVelocity);
  return Math.floor(base * stats.jumpMultiplier);
}

export function fastFallSpeed(maxFall: number, player: PlayerState): number {
  const tuning = movementTuningForSize(player.fighterSize ?? "medium");
  const mult = (MOVEMENT_BASE.fastFallMult * tuning.fastFall) / 100;
  return Math.floor(maxFall * mult);
}
