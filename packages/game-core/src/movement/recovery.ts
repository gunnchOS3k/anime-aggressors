import type { InputFrame, PlayerState } from "../types.js";
import { STAGE_WIDTH } from "../constants.js";
import { MOVEMENT_TUNING_FP } from "./movementTypes.js";

/** Basic up-recovery toward stage — not a full combat special. */
export function tryRecovery(player: PlayerState, input: InputFrame, stageCenterX = STAGE_WIDTH / 2): boolean {
  if (player.onGround || player.recoveryUsed) return false;
  if (player.movementState === "ledgeHang" || player.movementState === "ledgeGetup") return false;
  if (player.actionState === "hitstun") return false;
  if (!input.special) return false;

  const towardStage = stageCenterX > player.x ? 1 : stageCenterX < player.x ? -1 : player.facing;
  player.recoveryUsed = true;
  player.movementState = "recoveryFall";
  player.vy = MOVEMENT_TUNING_FP.recoveryVy;
  player.vx += towardStage * MOVEMENT_TUNING_FP.recoveryVxBoost;
  player.facing = towardStage as 1 | -1;
  player.onGround = false;
  player.fastFalling = false;
  player.actionState = "jumping";
  return true;
}

export function clearRecoveryOnLand(player: PlayerState): void {
  if (player.onGround) {
    player.recoveryUsed = false;
    if (player.movementState === "recoveryFall") {
      player.movementState = "idle";
    }
  }
}
