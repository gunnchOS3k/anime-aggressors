import type { InputFrame, PlayerState } from "../types.js";
import { MOVEMENT_TUNING_FRAMES, MOVEMENT_TUNING_FP } from "./movementTypes.js";
import { isMovementLocked } from "./landingLag.js";
import { computeDashSpeed, computeRunSpeed } from "./applyMovement.js";
import { movementTuningForSize } from "./movementTuning.js";

function preservesCombatState(player: PlayerState): boolean {
  return (
    player.actionState === "attacking" ||
    player.actionState === "special" ||
    player.actionState === "grabbing" ||
    player.actionState === "throwing" ||
    player.actionState === "shielding" ||
    player.actionState === "hitstun"
  );
}

function lerpVelocity(current: number, target: number, accel: number): number {
  if (current === target) return target;
  const step = Math.max(1, Math.floor(Math.abs(target - current) * (0.35 * accel)));
  if (current < target) return Math.min(target, current + step);
  return Math.max(target, current - step);
}

function horizontalInput(input: InputFrame): -1 | 0 | 1 {
  if (input.left && !input.right) return -1;
  if (input.right && !input.left) return 1;
  return 0;
}

/** Platform-fighter ground movement: dash start → run, skid turnaround, crouch. */
export function applyGroundMovement(player: PlayerState, input: InputFrame): void {
  if (!player.onGround) return;
  if (isMovementLocked(player)) return;
  if (player.actionState === "hitstun" || player.actionState === "defeated") return;
  if (player.actionState === "dodging") return;
  if (player.actionState === "auraCharging") {
    player.vx = Math.floor(player.vx * 0.45);
    return;
  }

  const dir = horizontalInput(input);
  const tuning = movementTuningForSize(player.fighterSize ?? "medium");
  const runSpeed = computeRunSpeed(player);
  const dashSpeed = computeDashSpeed(player);

  if (input.down && !input.jump && dir === 0 && Math.abs(player.vx) < MOVEMENT_TUNING_FP.skidVelocityThreshold) {
    player.movementState = "crouch";
    player.vx = 0;
    if (!preservesCombatState(player)) player.actionState = "idle";
    return;
  }

  if (dir === 0) {
    if (Math.abs(player.vx) > 0) {
      player.vx = Math.floor(player.vx * MOVEMENT_TUNING_FP.groundReleaseDecel);
      if (Math.abs(player.vx) < MOVEMENT_TUNING_FP.minGroundVelocity) {
        player.vx = 0;
        player.movementState = "idle";
        if (!preservesCombatState(player)) player.actionState = "idle";
      } else {
        player.movementState = "skid";
      }
    } else {
      player.movementState = "idle";
      if (!preservesCombatState(player)) player.actionState = "idle";
    }
    return;
  }

  player.facing = dir;

  const reversing =
    player.vx !== 0 &&
    Math.sign(player.vx) !== dir &&
    Math.abs(player.vx) >= MOVEMENT_TUNING_FP.skidVelocityThreshold;

  if (reversing) {
    if (player.movementState !== "skid") {
      player.movementState = "skid";
      player.dashFrames = MOVEMENT_TUNING_FRAMES.skidFrames;
    }
    player.vx = Math.floor(player.vx * MOVEMENT_TUNING_FP.skidDecelPerFrame);
    player.dashFrames -= 1;
    if (player.dashFrames <= 0 || Math.abs(player.vx) < MOVEMENT_TUNING_FP.minGroundVelocity) {
      player.vx = 0;
      player.dashFrames = MOVEMENT_TUNING_FRAMES.dashStartFrames;
      player.movementState = "dashStart";
      player.vx = dir * Math.floor(dashSpeed * 1.15);
    }
    if (!preservesCombatState(player)) player.actionState = "running";
    return;
  }

  const target = dir * runSpeed;

  if (player.movementState === "idle" || player.movementState === "crouch" || player.movementState === "landingLag") {
    player.movementState = "dashStart";
    player.dashFrames = MOVEMENT_TUNING_FRAMES.dashStartFrames;
    player.vx = dir * Math.floor(dashSpeed * 1.15);
    if (!preservesCombatState(player)) player.actionState = "running";
    return;
  }

  if (player.movementState === "dashStart") {
    player.dashFrames -= 1;
    player.vx = lerpVelocity(player.vx, target, tuning.acceleration);
    if (player.dashFrames <= 0) {
      player.movementState = "run";
    }
    if (!preservesCombatState(player)) player.actionState = "running";
    return;
  }

  player.movementState = Math.abs(player.vx) < runSpeed * 0.6 ? "walk" : "run";
  player.vx = lerpVelocity(player.vx, target, tuning.acceleration);
  if (!preservesCombatState(player)) player.actionState = "running";
}
