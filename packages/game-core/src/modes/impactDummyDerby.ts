import type { CreatedFighter } from "../createdFighter.js";
import { getDefaultCreatedFighter } from "../createdFighter.js";
import { SIM_HZ } from "../constants.js";
import { FP_SCALE } from "../constants.js";
import type { DerbyInput, ImpactDummyDerbyState } from "./impactDummyDerbyTypes.js";
import { pushDerbyEvent } from "./impactDummyDerbyEvents.js";
import {
  computeDerbyScore,
  gradeFromScore,
  syncLegacyScoreFields,
} from "./impactDummyDerbyScoring.js";
import {
  PLATFORM_Y,
  advanceBatSwing,
  fallbackLaunch,
  integrateDummy,
  integratePlayer,
  tryBatLaunch,
  tryNormalAttackHit,
} from "./impactDummyDerbyPhysics.js";
import { comboWindowForFighter, tickDerbyElements } from "./impactDummyDerbyElements.js";

export {
  PLATFORM_Y,
  PLATFORM_LEFT,
  PLATFORM_RIGHT,
  RUN_SPEED,
  JUMP_V,
  BAT_STARTUP,
  BAT_ACTIVE,
  BAT_RECOVERY,
} from "./impactDummyDerbyPhysics.js";
export { GRAVITY } from "./impactDummyDerbyElements.js";

export const DERBY_COUNTDOWN_FRAMES = 3 * SIM_HZ;
export const DAMAGE_PHASE_FRAMES = 10 * SIM_HZ;
export const LAUNCH_WINDOW_FRAMES = 3 * SIM_HZ;

export type {
  ImpactDummyDerbyPhase,
  DerbyPhase,
  DerbyPlayerState,
  ImpactDummyState,
  KineticBatState,
  DerbyGrade,
  ImpactDummyDerbyState,
  DerbyInput,
} from "./impactDummyDerbyTypes.js";

export type { ImpactDummyDerbyEvent } from "./impactDummyDerbyEvents.js";
export { computeDerbyScore, gradeFromScore, distanceDisplayUnits } from "./impactDummyDerbyScoring.js";

function cloneState(s: ImpactDummyDerbyState): ImpactDummyDerbyState {
  return {
    ...s,
    player: { ...s.player },
    dummy: { ...s.dummy },
    kineticBat: { ...s.kineticBat },
    events: [...s.events],
  };
}

function createPlayerSpawn() {
  return {
    x: 600 * FP_SCALE,
    y: PLATFORM_Y - 64 * FP_SCALE,
    vx: 0,
    vy: 0,
    facing: 1 as const,
    onGround: true,
    jumpsRemaining: 1,
    fastFalling: false,
    actionState: "idle" as const,
    actionFrame: 0,
    shieldHealth: 100,
  };
}

function createDummySpawn() {
  return {
    x: 1200 * FP_SCALE,
    y: PLATFORM_Y - 64 * FP_SCALE,
    vx: 0,
    vy: 0,
    damage: 0,
    hitstunFrames: 0,
    grounded: true,
    launched: false,
    landed: false,
    burnTicksRemaining: 0,
    slowFramesRemaining: 0,
    slowMultiplierFp: 100,
  };
}

export function createInitialDerbyState(
  seed = 1,
  personalBest = 0,
  fighter?: CreatedFighter,
): ImpactDummyDerbyState {
  const f = fighter ?? getDefaultCreatedFighter(0);
  const state: ImpactDummyDerbyState = {
    mode: "impactDummyDerby",
    frame: 0,
    phase: "ready",
    phaseFrame: 0,
    fighter: f,
    player: createPlayerSpawn(),
    dummy: createDummySpawn(),
    kineticBat: {
      available: false,
      equipped: false,
      swingState: "idle",
      swingFrame: 0,
      sweetSpotActive: false,
    },
    timerFramesRemaining: DAMAGE_PHASE_FRAMES,
    finalLaunchFramesRemaining: LAUNCH_WINDOW_FRAMES,
    comboCount: 0,
    bestCombo: 0,
    totalHits: 0,
    comboWindowFrames: comboWindowForFighter(f),
    lastHitFrame: -9999,
    totalDamageDealt: 0,
    launchOriginX: 1200 * FP_SCALE,
    flightDistance: 0,
    finalDistance: 0,
    finalLaunchSpeed: 0,
    finalLaunchAngleDeg: 0,
    score: 0,
    grade: "—",
    personalBest,
    bestScore: personalBest,
    launchSpeed: 0,
    distance: 0,
    kineticBatAvailable: false,
    kineticBatEquipped: false,
    seed,
    events: [],
  };
  syncLegacyScoreFields(state);
  return state;
}

function advancePhase(state: ImpactDummyDerbyState): void {
  state.phaseFrame += 1;

  if (state.phase === "ready" && state.phaseFrame >= 1) {
    state.phase = "countdown";
    state.phaseFrame = 0;
    state.events = pushDerbyEvent(state.events, { type: "phaseChanged", frame: state.frame, phase: "countdown" });
  } else if (state.phase === "countdown" && state.phaseFrame >= DERBY_COUNTDOWN_FRAMES) {
    state.phase = "damage";
    state.phaseFrame = 0;
    state.timerFramesRemaining = DAMAGE_PHASE_FRAMES;
    state.events = pushDerbyEvent(state.events, { type: "phaseChanged", frame: state.frame, phase: "damage" });
  } else if (state.phase === "damage") {
    state.timerFramesRemaining = Math.max(0, DAMAGE_PHASE_FRAMES - state.phaseFrame);
    if (state.phaseFrame >= DAMAGE_PHASE_FRAMES) {
      state.phase = "finalLaunch";
      state.phaseFrame = 0;
      state.finalLaunchFramesRemaining = LAUNCH_WINDOW_FRAMES;
      state.kineticBat.available = true;
      state.kineticBat.equipped = true;
      state.events = pushDerbyEvent(state.events, { type: "phaseChanged", frame: state.frame, phase: "finalLaunch" });
      state.events = pushDerbyEvent(state.events, { type: "batEquipped", frame: state.frame });
    }
  } else if (state.phase === "finalLaunch") {
    state.finalLaunchFramesRemaining = Math.max(0, LAUNCH_WINDOW_FRAMES - state.phaseFrame);
    if (state.phaseFrame >= LAUNCH_WINDOW_FRAMES && !state.dummy.launched) {
      fallbackLaunch(state);
    }
  } else if (state.phase === "landed" && state.phaseFrame >= SIM_HZ) {
    state.score = computeDerbyScore(state);
    state.grade = gradeFromScore(state.score);
    if (state.score > state.personalBest) {
      state.personalBest = state.score;
    }
    state.phase = "results";
    state.phaseFrame = 0;
    syncLegacyScoreFields(state);
    state.events = pushDerbyEvent(state.events, {
      type: "scored",
      frame: state.frame,
      score: state.score,
      grade: state.grade,
    });
  }
}

export function simulateDerbyFrame(
  state: ImpactDummyDerbyState,
  input: DerbyInput = {},
): ImpactDummyDerbyState {
  const next = cloneState(state);
  next.frame += 1;

  if (next.phase === "results") {
    syncLegacyScoreFields(next);
    return next;
  }

  const i = {
    left: input.left ?? false,
    right: input.right ?? false,
    up: input.up ?? false,
    down: input.down ?? false,
    jump: input.jump ?? false,
    attack: input.attack ?? false,
    special: input.special ?? false,
    shield: input.shield ?? false,
    dodge: input.dodge ?? false,
    grab: input.grab ?? false,
  };

  integratePlayer(next.player, next.fighter, i);
  tickDerbyElements(next);

  if (next.phase === "damage") {
    tryNormalAttackHit(next);
  }

  if (next.phase === "finalLaunch") {
    advanceBatSwing(next.kineticBat, i.attack);
    if (!tryBatLaunch(next, i)) {
      tryNormalAttackHit(next);
    }
  }

  integrateDummy(next);
  advancePhase(next);
  syncLegacyScoreFields(next);
  return next;
}

export function resetDerbyForRetry(state: ImpactDummyDerbyState): ImpactDummyDerbyState {
  const fresh = createInitialDerbyState(state.seed, state.personalBest, state.fighter);
  fresh.phase = "countdown";
  fresh.phaseFrame = 0;
  fresh.events = pushDerbyEvent(fresh.events, { type: "phaseChanged", frame: 0, phase: "countdown" });
  return fresh;
}

export function derbyStateHash(state: ImpactDummyDerbyState): string {
  const parts = [
    state.frame,
    state.phase,
    state.player.x,
    state.player.y,
    state.dummy.damage,
    state.dummy.x,
    state.finalDistance,
    state.score,
    state.comboCount,
    state.bestCombo,
  ];
  let h = state.seed;
  for (const p of parts) {
    h = (h * 31 + (typeof p === "string" ? p.charCodeAt(0) : p)) | 0;
  }
  return (h >>> 0).toString(16).padStart(8, "0");
}

export function replayDerby(
  initial: ImpactDummyDerbyState,
  inputs: DerbyInput[],
): { final: ImpactDummyDerbyState; hash: string } {
  let state = cloneState(initial);
  for (const input of inputs) {
    state = simulateDerbyFrame(state, input);
  }
  return { final: state, hash: derbyStateHash(state) };
}
