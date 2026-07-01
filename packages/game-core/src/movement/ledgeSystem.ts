import type { InputFrame, PlayerState } from "../types.js";
import type { StageLayoutDef, StageLedge } from "../stageLayouts.js";
import { FP_SCALE } from "../constants.js";
import { MOVEMENT_TUNING_FRAMES, MOVEMENT_TUNING_FP } from "./movementTypes.js";
import { computeJumpVelocity } from "./jumpSystem.js";

function towardStageInput(ledge: StageLedge, input: InputFrame): boolean {
  return ledge.side === "left" ? input.right : input.left;
}

function awayFromStageInput(ledge: StageLedge, input: InputFrame): boolean {
  return ledge.side === "left" ? input.left : input.right;
}

export function findLedge(layout: StageLayoutDef, id: string): StageLedge | undefined {
  return layout.ledges.find((l) => l.id === id);
}

export function tryLedgeGrab(player: PlayerState, layout: StageLayoutDef): boolean {
  if (player.onGround || player.ledgeCooldownFrames > 0) return false;
  if (player.movementState === "ledgeHang") return false;
  if (player.vy <= 0) return false;

  for (const ledge of layout.ledges) {
    const xDist = Math.abs(player.x - ledge.x);
    const yDist = player.y - ledge.y;
    if (xDist > MOVEMENT_TUNING_FP.ledgeGrabXRange) continue;
    if (yDist < -4 * FP_SCALE || yDist > MOVEMENT_TUNING_FP.ledgeGrabYRange) continue;

    const movingToward =
      (ledge.side === "left" && (player.vx <= 0 || player.facing < 0)) ||
      (ledge.side === "right" && (player.vx >= 0 || player.facing > 0));
    if (!movingToward) continue;

    player.movementState = "ledgeHang";
    player.grabbedLedgeId = ledge.id;
    player.ledgeStateFrames = MOVEMENT_TUNING_FRAMES.ledgeHangMaxFrames;
    player.x = ledge.x;
    player.y = ledge.y;
    player.vx = 0;
    player.vy = 0;
    player.onGround = false;
    player.fastFalling = false;
    player.actionState = "falling";
    return true;
  }
  return false;
}

export function tickLedgeHang(player: PlayerState, layout: StageLayoutDef, input: InputFrame | undefined): void {
  if (player.movementState !== "ledgeHang") return;
  const ledge = findLedge(layout, player.grabbedLedgeId);
  if (!ledge) {
    releaseLedge(player);
    return;
  }

  player.ledgeStateFrames -= 1;
  if (player.ledgeStateFrames <= 0) {
    releaseLedge(player);
    return;
  }

  if (!input) return;

  if (input.jump || input.up) {
    startLedgeJump(player, ledge);
    return;
  }
  if (towardStageInput(ledge, input)) {
    startLedgeGetup(player, ledge, layout);
    return;
  }
  if (awayFromStageInput(ledge, input) || input.down) {
    releaseLedge(player);
  }
}

function startLedgeJump(player: PlayerState, ledge: StageLedge): void {
  const toward = ledge.side === "left" ? 1 : -1;
  player.movementState = "ledgeJump";
  player.ledgeStateFrames = MOVEMENT_TUNING_FRAMES.ledgeJumpFrames;
  player.grabbedLedgeId = "";
  player.vy = computeJumpVelocity(player, false);
  player.vx = toward * Math.floor(Math.abs(computeJumpVelocity(player, false)) * 0.55);
  player.facing = toward as 1 | -1;
  player.onGround = false;
  player.actionState = "jumping";
  player.ledgeCooldownFrames = MOVEMENT_TUNING_FRAMES.ledgeRegrabCooldown;
}

function startLedgeGetup(player: PlayerState, ledge: StageLedge, layout: StageLayoutDef): void {
  const plat = layout.platforms.find((p) => p.id === ledge.platformId);
  player.movementState = "ledgeGetup";
  player.ledgeStateFrames = MOVEMENT_TUNING_FRAMES.ledgeGetupFrames;
  player.grabbedLedgeId = "";
  if (plat) {
    const inset = ledge.side === "left" ? 6 * FP_SCALE : -6 * FP_SCALE;
    player.x = ledge.x + inset;
    player.y = plat.y;
  }
  player.vx = 0;
  player.vy = 0;
  player.onGround = true;
  player.currentPlatformId = ledge.platformId;
  player.ledgeCooldownFrames = MOVEMENT_TUNING_FRAMES.ledgeRegrabCooldown;
  player.actionState = "idle";
}

export function releaseLedge(player: PlayerState): void {
  player.movementState = "airborne";
  player.grabbedLedgeId = "";
  player.ledgeStateFrames = 0;
  player.ledgeCooldownFrames = MOVEMENT_TUNING_FRAMES.ledgeRegrabCooldown;
  player.onGround = false;
  player.actionState = "falling";
  player.vy = Math.max(player.vy, (2 * FP_SCALE) / 60);
}

export function tickLedgeMovementState(player: PlayerState): void {
  if (player.movementState === "ledgeJump" || player.movementState === "ledgeGetup") {
    player.ledgeStateFrames -= 1;
    if (player.ledgeStateFrames <= 0) {
      player.movementState = player.onGround ? "idle" : "airborne";
    }
  }
  if (player.ledgeCooldownFrames > 0) {
    player.ledgeCooldownFrames -= 1;
  }
}

export function isLedgeMovement(player: PlayerState): boolean {
  return (
    player.movementState === "ledgeHang" ||
    player.movementState === "ledgeGetup"
  );
}
