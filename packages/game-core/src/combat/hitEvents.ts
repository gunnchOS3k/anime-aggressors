import type { HitStrength } from "./combatTuning.js";

export type CameraImpulseKind = "lightHit" | "heavyHit" | "launch" | "ko" | "super" | "beamClash";

export type HitEvent = {
  frame: number;
  attackerPlayerId: number;
  victimPlayerId: number;
  moveId: string;
  damage: number;
  preHitVictimDamage: number;
  postHitVictimDamage: number;
  launchAngleDeg: number;
  knockbackX: number;
  knockbackY: number;
  hitlagFrames: number;
  hitstunFrames: number;
  hitStrength: HitStrength;
  element: string;
  cameraImpulseKind: CameraImpulseKind;
};

export function createHitEvent(partial: Omit<HitEvent, "cameraImpulseKind"> & { cameraImpulseKind?: CameraImpulseKind }): HitEvent {
  return {
    ...partial,
    cameraImpulseKind: partial.cameraImpulseKind ?? "lightHit",
  };
}
