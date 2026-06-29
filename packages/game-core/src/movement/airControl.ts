import type { PlayerState } from "../types.js";
import { MOVEMENT_BASE, movementTuningForSize, scaledMovementValue } from "./movementTuning.js";

export function computeAirDriftSpeed(player: PlayerState): number {
  const tuning = movementTuningForSize(player.fighterSize ?? "medium");
  let speed = scaledMovementValue(MOVEMENT_BASE.airDrift, tuning.airDrift);
  if (player.airDriftBonusFrames > 0) {
    speed = Math.floor(speed * 1.12);
  }
  return speed;
}
