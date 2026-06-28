import { getAllFighterMovesets, type MoveDefinition } from "@anime-aggressors/game-core";

export type MotionArc =
  | "jab"
  | "slash"
  | "uppercut"
  | "sweep"
  | "beam"
  | "orb"
  | "dash"
  | "slam";

export type CameraImpulse = "none" | "light" | "medium" | "heavy" | "super";

export type MoveAnimationSpec = {
  moveId: string;
  animationKey: string;
  anticipationFrames: number;
  strikeFrame: number;
  followThroughFrames: number;
  motionArc: MotionArc;
  cameraImpulse?: CameraImpulse;
  trailStyle?: string;
};

function motionArcForMove(move: MoveDefinition): MotionArc {
  if (move.slot === "super") {
    if (move.energyKind === "orb") return "orb";
    if (move.energyKind === "shockwave") return "slam";
    return "beam";
  }
  if (move.slot === "sideSpecial" && move.displayName.toLowerCase().includes("dash")) return "dash";
  if (move.slot === "sideSpecial" && move.displayName.toLowerCase().includes("rush")) return "dash";
  if (move.slot === "sideSpecial" && move.displayName.toLowerCase().includes("step")) return "dash";
  if (move.slot === "sideSpecial" && move.displayName.toLowerCase().includes("blink")) return "dash";
  if (move.slot === "sideSpecial" && move.displayName.toLowerCase().includes("glide")) return "dash";
  if (move.slot === "sideSpecial" && move.displayName.toLowerCase().includes("slide")) return "dash";
  if (move.category === "jab") return "jab";
  if (move.slot === "upAttack" || move.slot === "upAir") return "uppercut";
  if (move.slot === "downAttack" || move.slot === "downAir") return "sweep";
  if (move.category === "throw") return "slam";
  if (move.category === "special") return "beam";
  return "slash";
}

function cameraImpulseForMove(move: MoveDefinition): CameraImpulse {
  if (move.slot === "super") return "super";
  if (move.comboFinisher) return "heavy";
  if (move.category === "special") return "medium";
  if (move.category === "tilt") return "light";
  return "none";
}

function buildSpec(move: MoveDefinition): MoveAnimationSpec {
  return {
    moveId: move.id,
    animationKey: move.animationKey,
    anticipationFrames: Math.max(2, Math.floor(move.startupFrames * 0.4)),
    strikeFrame: move.startupFrames,
    followThroughFrames: move.recoveryFrames,
    motionArc: motionArcForMove(move),
    cameraImpulse: cameraImpulseForMove(move),
    trailStyle: move.vfxStyle,
  };
}

const MOVE_ANIMATION_MAP: Record<string, MoveAnimationSpec> = Object.fromEntries(
  getAllFighterMovesets().map((m) => [m.id, buildSpec(m)]),
);

export function getMoveAnimationSpec(moveId: string): MoveAnimationSpec | undefined {
  return MOVE_ANIMATION_MAP[moveId];
}

export function getAllMoveAnimationSpecs(): MoveAnimationSpec[] {
  return Object.values(MOVE_ANIMATION_MAP);
}

export { MOVE_ANIMATION_MAP };
