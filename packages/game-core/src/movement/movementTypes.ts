/** Deterministic movement vocabulary — separate from combat actionState. */
export type MovementState =
  | "idle"
  | "walk"
  | "dashStart"
  | "run"
  | "skid"
  | "crouch"
  | "jumpSquat"
  | "airborne"
  | "fastFall"
  | "landingLag"
  | "ledgeHang"
  | "ledgeGetup"
  | "ledgeJump"
  | "recoveryFall";

export const MOVEMENT_TUNING_FRAMES = {
  dashStartFrames: 4,
  skidFrames: 5,
  jumpSquatFrames: 3,
  landingLagNormal: 4,
  landingLagFastFall: 8,
  ledgeHangMaxFrames: 180,
  ledgeRegrabCooldown: 30,
  ledgeGetupFrames: 12,
  ledgeJumpFrames: 8,
} as const;

export const MOVEMENT_TUNING_FP = {
  /** Minimum |vx| before turnaround skid triggers (per-frame fixed-point). */
  skidVelocityThreshold: 20,
  /** Velocity below which grounded release snaps to idle. */
  minGroundVelocity: 8,
  groundReleaseDecel: 0.55,
  skidDecelPerFrame: 0.4,
  ledgeGrabXRange: 10 * 256,
  ledgeGrabYRange: 14 * 256,
  recoveryVy: (-14 * 256) / 60,
  recoveryVxBoost: (8 * 256) / 60,
} as const;

export function defaultMovementState(): MovementState {
  return "idle";
}

export function resetMovementFields(player: {
  movementState: MovementState;
  dashFrames: number;
  jumpSquatFrames: number;
  jumpShortHop: boolean;
  landingLagFrames: number;
  ledgeStateFrames: number;
  grabbedLedgeId: string;
  ledgeCooldownFrames: number;
  recoveryUsed: boolean;
}): void {
  player.movementState = "idle";
  player.dashFrames = 0;
  player.jumpSquatFrames = 0;
  player.jumpShortHop = false;
  player.landingLagFrames = 0;
  player.ledgeStateFrames = 0;
  player.grabbedLedgeId = "";
  player.ledgeCooldownFrames = 0;
  player.recoveryUsed = false;
}
