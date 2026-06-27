import type { CreatedFighter } from "../createdFighter.js";
import type { ImpactDummyDerbyEvent } from "./impactDummyDerbyEvents.js";

export type ImpactDummyDerbyPhase =
  | "ready"
  | "countdown"
  | "damage"
  | "finalLaunch"
  | "flight"
  | "landed"
  | "results";

/** @deprecated Use ImpactDummyDerbyPhase */
export type DerbyPhase = ImpactDummyDerbyPhase | "damage_phase" | "launch_window";

export type DerbyPlayerState = {
  x: number;
  y: number;
  vx: number;
  vy: number;
  facing: 1 | -1;
  onGround: boolean;
  jumpsRemaining: number;
  fastFalling: boolean;
  actionState: "idle" | "running" | "jumping" | "falling" | "attacking" | "special" | "shielding" | "dodging";
  actionFrame: number;
  shieldHealth: number;
};

export type ImpactDummyState = {
  x: number;
  y: number;
  vx: number;
  vy: number;
  damage: number;
  hitstunFrames: number;
  grounded: boolean;
  launched: boolean;
  landed: boolean;
  burnTicksRemaining: number;
  slowFramesRemaining: number;
  slowMultiplierFp: number;
};

export type KineticBatState = {
  available: boolean;
  equipped: boolean;
  swingState: "idle" | "startup" | "active" | "recovery";
  swingFrame: number;
  sweetSpotActive: boolean;
};

export type DerbyGrade = "D" | "C" | "B" | "A" | "S" | "SS";

export type ImpactDummyDerbyState = {
  mode: "impactDummyDerby";
  frame: number;
  phase: ImpactDummyDerbyPhase;
  phaseFrame: number;

  player: DerbyPlayerState;
  dummy: ImpactDummyState;
  kineticBat: KineticBatState;
  fighter: CreatedFighter;

  timerFramesRemaining: number;
  finalLaunchFramesRemaining: number;

  comboCount: number;
  bestCombo: number;
  totalHits: number;
  comboWindowFrames: number;
  lastHitFrame: number;

  totalDamageDealt: number;
  launchOriginX: number;
  flightDistance: number;
  finalDistance: number;
  finalLaunchSpeed: number;
  finalLaunchAngleDeg: number;

  score: number;
  grade: DerbyGrade | "—";
  personalBest: number;

  /** @deprecated use personalBest */
  bestScore: number;
  /** @deprecated use finalLaunchSpeed */
  launchSpeed: number;
  /** @deprecated use finalDistance */
  distance: number;
  /** @deprecated use kineticBat.available */
  kineticBatAvailable: boolean;
  /** @deprecated use kineticBat.equipped */
  kineticBatEquipped: boolean;

  seed: number;
  events: ImpactDummyDerbyEvent[];
};

export type DerbyInput = {
  left?: boolean;
  right?: boolean;
  up?: boolean;
  down?: boolean;
  jump?: boolean;
  attack?: boolean;
  special?: boolean;
  shield?: boolean;
  dodge?: boolean;
  grab?: boolean;
};
