import type { InputFrame, PlayerState } from "../types.js";
import { getCharacter } from "../characters.js";
import { MOVEMENT_BASE, movementTuningForSize, scaledMovementValue } from "./movementTuning.js";
import { computeAirDriftSpeed } from "./airControl.js";

export function computeRunSpeed(player: PlayerState): number {
  const char = getCharacter(player.characterId);
  const tuning = movementTuningForSize(player.fighterSize ?? "medium");
  const slow = player.slowMultiplierFp ? player.slowMultiplierFp / 100 : 1;
  const base = scaledMovementValue(MOVEMENT_BASE.runSpeed, tuning.runSpeed);
  return Math.floor(base * slow * (char.runSpeedMult / 100));
}

export function computeDashSpeed(player: PlayerState): number {
  const tuning = movementTuningForSize(player.fighterSize ?? "medium");
  return scaledMovementValue(MOVEMENT_BASE.dashSpeed, tuning.dashSpeed);
}

export function applyHorizontalMovement(player: PlayerState, input: InputFrame): void {
  if (player.actionState === "hitstun" || player.actionState === "defeated") return;
  if (player.actionState === "dodging") return;

  if (player.actionState === "auraCharging") {
    player.vx = Math.floor(player.vx * MOVEMENT_BASE.chargeMoveMult);
    return;
  }

  const canMove =
    player.onGround ||
    player.actionState === "jumping" ||
    player.actionState === "falling" ||
    player.actionState === "idle" ||
    player.actionState === "running";

  if (!canMove) return;

  const tuning = movementTuningForSize(player.fighterSize ?? "medium");
  const targetSpeed = player.onGround ? computeRunSpeed(player) : computeAirDriftSpeed(player);
  const accel = tuning.acceleration;

  if (input.left) {
    const desired = -targetSpeed;
    player.vx = lerpVelocity(player.vx, desired, accel);
    player.facing = -1;
    if (player.onGround) player.actionState = "running";
  } else if (input.right) {
    const desired = targetSpeed;
    player.vx = lerpVelocity(player.vx, desired, accel);
    player.facing = 1;
    if (player.onGround) player.actionState = "running";
  } else if (player.onGround && player.actionState === "running") {
    player.vx = Math.floor(player.vx * 0.55);
    if (Math.abs(player.vx) < 8) {
      player.vx = 0;
      player.actionState = "idle";
    }
  }
}

function lerpVelocity(current: number, target: number, accel: number): number {
  if (current === target) return target;
  const step = Math.max(1, Math.floor(Math.abs(target - current) * (0.35 * accel)));
  if (current < target) return Math.min(target, current + step);
  return Math.max(target, current - step);
}

export function applyDash(player: PlayerState): void {
  player.vx = player.facing * computeDashSpeed(player);
  player.invulnFrames = Math.max(player.invulnFrames, 6);
}

export { computeJumpVelocity } from "./jumpSystem.js";
