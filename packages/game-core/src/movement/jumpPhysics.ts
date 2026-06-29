import type { InputFrame, PlayerState } from "../types.js";
import { MOVEMENT_BASE, movementTuningForSize, scaledMovementValue } from "./movementTuning.js";
import { getPlayerSizeStats } from "../fighterCreation.js";

/** @deprecated Use jumpSystem.ts */
export function computeJumpVelocity(player: PlayerState): number {
  const tuning = movementTuningForSize(player.fighterSize ?? "medium");
  const stats = getPlayerSizeStats(player);
  const base = scaledMovementValue(MOVEMENT_BASE.jumpVelocity, tuning.jumpVelocity);
  return Math.floor(base * stats.jumpMultiplier);
}

export { fastFallSpeed } from "./jumpSystem.js";
