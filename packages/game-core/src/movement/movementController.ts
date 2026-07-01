import type { InputFrame, PlayerState } from "../types.js";
import type { StageLayoutDef } from "../stageLayouts.js";
import { beginDropThrough, isPassThroughPlatform } from "../stageCollision.js";
import { applyGroundMovement } from "./groundMovement.js";
import { applyHorizontalMovement } from "./applyMovement.js";
import { isMovementLocked, tickLandingLag } from "./landingLag.js";
import {
  isLedgeMovement,
  tickLedgeHang,
  tickLedgeMovementState,
  tryLedgeGrab,
} from "./ledgeSystem.js";
import { tryRecovery, clearRecoveryOnLand } from "./recovery.js";
import {
  bufferJumpInput,
  consumeJumpBuffer,
  fastFallSpeed,
  getMaxAirJumpsForPlayer,
  getMaxJumpsForPlayer,
  JUMP_TUNING,
  queueJumpSquat,
  tickJumpSquat,
  tickJumpHold,
  canCoyoteJump,
  computeDoubleJumpVelocity,
  computeJumpVelocity,
} from "./jumpSystem.js";
import { MAX_FALL_SPEED } from "../constants.js";

export function tickMovementTimers(player: PlayerState): void {
  tickLandingLag(player);
  tickLedgeMovementState(player);
  clearRecoveryOnLand(player);
}

export function processMovementInput(
  player: PlayerState,
  input: InputFrame,
  layout: StageLayoutDef,
  stageCenterX: number,
): void {
  if (player.actionState === "defeated") return;

  const jumpJustPressed = input.jump && !player.wasJumpHeld;
  bufferJumpInput(player, jumpJustPressed);

  if (player.movementState === "ledgeHang") {
    tickLedgeHang(player, layout, input);
    player.wasJumpHeld = !!input.jump;
    return;
  }

  if (isMovementLocked(player) && player.movementState !== "jumpSquat") {
    player.wasJumpHeld = !!input.jump;
    return;
  }

  const wantsDropThrough =
    jumpJustPressed &&
    input.down &&
    player.onGround &&
    player.currentPlatformId !== "" &&
    isPassThroughPlatform(layout, player.currentPlatformId);

  if (wantsDropThrough) {
    beginDropThrough(player, player.currentPlatformId);
    player.movementState = "airborne";
  } else {
    let wantsJump = jumpJustPressed;
    if (!wantsJump && player.jumpBufferFrames > 0 && (player.onGround || canCoyoteJump(player))) {
      wantsJump = consumeJumpBuffer(player);
    } else if (wantsJump && player.jumpBufferFrames > 0) {
      consumeJumpBuffer(player);
    }

    if (wantsJump) {
      if (player.aura.charging) {
        player.aura.charging = false;
        player.currentMoveId = "none";
        player.actionState = "idle";
      }
      if (player.onGround || canCoyoteJump(player)) {
        if (player.movementState !== "jumpSquat") {
          queueJumpSquat(player);
        }
      } else {
        tryAirJump(player);
      }
    } else if (tryRecovery(player, input, stageCenterX)) {
      // recovery consumed
    }
  }

  if (player.onGround && player.movementState !== "jumpSquat") {
    applyGroundMovement(player, input);
  } else if (
    player.movementState !== "ledgeJump" &&
    player.movementState !== "recoveryFall" &&
    player.movementState !== "jumpSquat" &&
    !player.onGround
  ) {
    applyHorizontalMovement(player, input);
    player.movementState = player.fastFalling ? "fastFall" : "airborne";
    player.actionState = player.vy < 0 ? "jumping" : "falling";
  }

  if (!player.onGround && input.down && player.vy >= 0) {
    player.fastFalling = true;
    player.movementState = "fastFall";
  }

  tickJumpHold(player, !!input.jump);
}

function tryAirJump(player: PlayerState): void {
  const maxAir = getMaxAirJumpsForPlayer(player);
  if (!player.onGround && player.jumpsUsed === 1 && maxAir >= 1) {
    player.jumpsUsed = 2;
    player.jumpsRemaining = Math.max(0, getMaxJumpsForPlayer(player) - player.jumpsUsed);
    player.vy = computeDoubleJumpVelocity(player);
    player.movementState = "airborne";
    player.actionState = "jumping";
    player.actionFrame = 0;
    player.fastFalling = false;
    player.jumpHoldFrames = JUMP_TUNING.shortHopReleaseFrames;
  }
}

export function afterMovementPhysics(
  player: PlayerState,
  layout: StageLayoutDef,
  wasOnGround: boolean,
  wasFastFalling: boolean,
): void {
  if (!wasOnGround && player.onGround) {
    clearRecoveryOnLand(player);
  }

  if (player.onGround) {
    if (player.movementState === "airborne" || player.movementState === "fastFall" || player.movementState === "ledgeJump") {
      player.movementState = "idle";
    }
    return;
  }

  if (!isLedgeMovement(player) && player.movementState !== "ledgeJump") {
    tryLedgeGrab(player, layout);
  }

  if (!player.onGround && wasOnGround) {
    player.movementState = "airborne";
  }
}

export function applyFastFallCap(player: PlayerState): number {
  if (player.fastFalling && !player.onGround) {
    return fastFallSpeed(MAX_FALL_SPEED, player);
  }
  return MAX_FALL_SPEED;
}

export function tickJumpSquatPhase(player: PlayerState, jumpHeld: boolean): void {
  if (player.movementState === "jumpSquat") {
    tickJumpSquat(player, jumpHeld);
  }
}

export { tickJumpSquat, queueJumpSquat };
