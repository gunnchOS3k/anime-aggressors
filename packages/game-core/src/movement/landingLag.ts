import type { PlayerState } from "../types.js";
import { MOVEMENT_TUNING_FRAMES } from "./movementTypes.js";

export function applyLandingLag(player: PlayerState, fromFastFall: boolean): void {
  player.landingLagFrames = fromFastFall
    ? MOVEMENT_TUNING_FRAMES.landingLagFastFall
    : MOVEMENT_TUNING_FRAMES.landingLagNormal;
  player.movementState = "landingLag";
  player.vx = Math.floor(player.vx * 0.5);
}

export function tickLandingLag(player: PlayerState): void {
  if (player.landingLagFrames <= 0) return;
  player.landingLagFrames -= 1;
  if (player.landingLagFrames === 0 && player.onGround) {
    player.movementState = Math.abs(player.vx) > 0 ? "run" : "idle";
  }
}

export function isMovementLocked(player: PlayerState): boolean {
  return (
    player.landingLagFrames > 0 ||
    player.movementState === "jumpSquat" ||
    player.movementState === "ledgeHang" ||
    player.movementState === "ledgeGetup"
  );
}
