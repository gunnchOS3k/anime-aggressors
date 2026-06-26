import type { InputFrame } from "../types.js";
import { FP_SCALE, SIM_HZ } from "../constants.js";

export type DerbyPhase =
  | "ready"
  | "countdown"
  | "damage_phase"
  | "launch_window"
  | "flight"
  | "landed"
  | "results";

export type DerbyPlayer = {
  x: number;
  y: number;
  vx: number;
  vy: number;
  facing: 1 | -1;
  onGround: boolean;
  actionState: "idle" | "running" | "jumping" | "falling" | "attacking" | "special";
  actionFrame: number;
};

export type DerbyDummy = {
  x: number;
  y: number;
  vx: number;
  vy: number;
  damage: number;
  hitstunFrames: number;
  launched: boolean;
};

export type ImpactDummyDerbyState = {
  frame: number;
  phase: DerbyPhase;
  phaseFrame: number;
  player: DerbyPlayer;
  dummy: DerbyDummy;
  kineticBatAvailable: boolean;
  kineticBatEquipped: boolean;
  totalDamageDealt: number;
  launchSpeed: number;
  launchOriginX: number;
  distance: number;
  score: number;
  grade: string;
  bestScore: number;
  seed: number;
};

export type DerbyInput = Partial<
  Pick<InputFrame, "left" | "right" | "up" | "down" | "jump" | "attack" | "special" | "dodge">
>;

export const DERBY_COUNTDOWN_FRAMES = 3 * SIM_HZ;
export const DAMAGE_PHASE_FRAMES = 10 * SIM_HZ;
export const LAUNCH_WINDOW_FRAMES = 3 * SIM_HZ;
export const PLATFORM_Y = 900 * FP_SCALE;
export const PLATFORM_LEFT = 200 * FP_SCALE;
export const PLATFORM_RIGHT = 2200 * FP_SCALE;
export const GRAVITY = (12 * FP_SCALE) / SIM_HZ;
export const RUN_SPEED = (7 * FP_SCALE) / SIM_HZ;
export const JUMP_V = -(14 * FP_SCALE) / SIM_HZ;

export function createInitialDerbyState(seed = 1, bestScore = 0): ImpactDummyDerbyState {
  return {
    frame: 0,
    phase: "ready",
    phaseFrame: 0,
    player: {
      x: 600 * FP_SCALE,
      y: PLATFORM_Y - 64 * FP_SCALE,
      vx: 0,
      vy: 0,
      facing: 1,
      onGround: true,
      actionState: "idle",
      actionFrame: 0,
    },
    dummy: {
      x: 1200 * FP_SCALE,
      y: PLATFORM_Y - 64 * FP_SCALE,
      vx: 0,
      vy: 0,
      damage: 0,
      hitstunFrames: 0,
      launched: false,
    },
    kineticBatAvailable: false,
    kineticBatEquipped: false,
    totalDamageDealt: 0,
    launchSpeed: 0,
    launchOriginX: 1200 * FP_SCALE,
    distance: 0,
    score: 0,
    grade: "—",
    bestScore,
    seed,
  };
}

function cloneState(s: ImpactDummyDerbyState): ImpactDummyDerbyState {
  return {
    ...s,
    player: { ...s.player },
    dummy: { ...s.dummy },
  };
}

function gradeFromScore(score: number): string {
  if (score >= 900) return "S";
  if (score >= 700) return "A";
  if (score >= 500) return "B";
  if (score >= 300) return "C";
  return "D";
}

function computeScore(state: ImpactDummyDerbyState): number {
  const distScore = Math.floor(state.distance / FP_SCALE);
  const dmgBonus = state.totalDamageDealt * 2;
  const speedBonus = Math.floor(state.launchSpeed / 4);
  return distScore + dmgBonus + speedBonus;
}

function applyPlayerInput(player: DerbyPlayer, input: DerbyInput): void {
  const i = {
    left: input.left ?? false,
    right: input.right ?? false,
    up: input.up ?? false,
    down: input.down ?? false,
    jump: input.jump ?? false,
    attack: input.attack ?? false,
    special: input.special ?? false,
    dodge: input.dodge ?? false,
  };
  if (player.actionState === "attacking" && player.actionFrame > 12) {
    player.actionState = "idle";
    player.actionFrame = 0;
  }

  if (i.left) {
    player.vx = -RUN_SPEED;
    player.facing = -1;
    if (player.onGround) player.actionState = "running";
  } else if (i.right) {
    player.vx = RUN_SPEED;
    player.facing = 1;
    if (player.onGround) player.actionState = "running";
  } else if (player.onGround && player.actionState === "running") {
    player.vx = 0;
    player.actionState = "idle";
  }

  if (i.jump && player.onGround) {
    player.vy = JUMP_V;
    player.onGround = false;
    player.actionState = "jumping";
  }

  if (i.dodge && player.onGround) {
    player.vx = player.facing * RUN_SPEED * 2;
  }

  if (i.attack && player.actionState !== "attacking") {
    player.actionState = "attacking";
    player.actionFrame = 0;
  }

  if (i.special && player.onGround) {
    player.actionState = "special";
    player.actionFrame = 0;
    player.vx = player.facing * RUN_SPEED * 1.5;
  }
}

function integratePlayer(player: DerbyPlayer): void {
  player.actionFrame += 1;
  player.vy += GRAVITY;
  player.x += player.vx;
  player.y += player.vy;

  if (player.y >= PLATFORM_Y - 64 * FP_SCALE) {
    player.y = PLATFORM_Y - 64 * FP_SCALE;
    player.vy = 0;
    player.onGround = true;
    if (player.actionState === "jumping" || player.actionState === "falling") {
      player.actionState = "idle";
    }
  } else {
    player.onGround = false;
    if (player.actionState === "idle" || player.actionState === "running") {
      player.actionState = "falling";
    }
  }

  if (player.x < PLATFORM_LEFT) player.x = PLATFORM_LEFT;
  if (player.x > PLATFORM_RIGHT) player.x = PLATFORM_RIGHT;
}

function hitDummy(
  state: ImpactDummyDerbyState,
  damage: number,
  kbX: number,
  kbY: number,
): void {
  const d = state.dummy;
  d.damage += damage;
  state.totalDamageDealt += damage;
  d.hitstunFrames = 8;
  d.vx += kbX;
  d.vy += kbY;
}

function tryPlayerHits(state: ImpactDummyDerbyState, kineticLaunch: boolean): void {
  const p = state.player;
  const d = state.dummy;
  if (p.actionFrame < 4 || p.actionFrame > 6) return;

  const reach = 80 * FP_SCALE;
  const inRange = Math.abs(p.x - d.x) < reach && Math.abs(p.y - d.y) < 96 * FP_SCALE;
  if (!inRange) return;

  if (kineticLaunch && state.kineticBatEquipped) {
    const power = 1 + d.damage / 50;
    const launchVx = p.facing * Math.floor(18 * FP_SCALE * power) / SIM_HZ;
    const launchVy = -Math.floor(12 * FP_SCALE * power) / SIM_HZ;
    d.vx = launchVx;
    d.vy = launchVy;
    d.launched = true;
    state.launchSpeed = Math.abs(launchVx) + Math.abs(launchVy);
    state.launchOriginX = d.x;
    state.phase = "flight";
    state.phaseFrame = 0;
    state.kineticBatEquipped = false;
    return;
  }

  const dmg = p.actionState === "special" ? 8 : 4;
  const kb = Math.floor((4 + d.damage / 20) * FP_SCALE) / SIM_HZ;
  hitDummy(state, dmg, p.facing * kb, -kb / 2);
}

function integrateDummy(state: ImpactDummyDerbyState): void {
  const d = state.dummy;
  if (d.hitstunFrames > 0) d.hitstunFrames -= 1;

  if (state.phase === "flight" || d.launched) {
    d.vy += GRAVITY;
    d.x += d.vx;
    d.y += d.vy;
    d.vx *= 0.998;

    if (d.y >= PLATFORM_Y - 32 * FP_SCALE && d.vy >= 0) {
      d.y = PLATFORM_Y - 32 * FP_SCALE;
      d.vy = 0;
      d.vx = 0;
      if (state.phase === "flight") {
        state.distance = Math.max(0, d.x - state.launchOriginX);
        state.phase = "landed";
        state.phaseFrame = 0;
      }
    }
  } else {
    d.y = PLATFORM_Y - 64 * FP_SCALE;
    d.vx *= 0.85;
    d.x += d.vx;
  }
}

function advancePhase(state: ImpactDummyDerbyState): void {
  state.phaseFrame += 1;

  if (state.phase === "ready" && state.phaseFrame >= 1) {
    state.phase = "countdown";
    state.phaseFrame = 0;
  } else if (state.phase === "countdown" && state.phaseFrame >= DERBY_COUNTDOWN_FRAMES) {
    state.phase = "damage_phase";
    state.phaseFrame = 0;
  } else if (state.phase === "damage_phase" && state.phaseFrame >= DAMAGE_PHASE_FRAMES) {
    state.phase = "launch_window";
    state.phaseFrame = 0;
    state.kineticBatAvailable = true;
    state.kineticBatEquipped = true;
  } else if (state.phase === "launch_window" && state.phaseFrame >= LAUNCH_WINDOW_FRAMES) {
    if (!state.dummy.launched) {
      tryPlayerHits(state, true);
      if (!state.dummy.launched) {
        hitDummy(state, 0, state.player.facing * 8, -4);
        state.dummy.launched = true;
        state.dummy.vx = state.player.facing * 6;
        state.dummy.vy = -8;
        state.launchOriginX = state.dummy.x;
        state.phase = "flight";
        state.phaseFrame = 0;
      }
    }
  } else if (state.phase === "landed" && state.phaseFrame >= SIM_HZ) {
    state.score = computeScore(state);
    state.grade = gradeFromScore(state.score);
    state.bestScore = Math.max(state.bestScore, state.score);
    state.phase = "results";
    state.phaseFrame = 0;
  }
}

export function simulateDerbyFrame(
  state: ImpactDummyDerbyState,
  input: DerbyInput = {},
): ImpactDummyDerbyState {
  const next = cloneState(state);
  next.frame += 1;

  if (next.phase === "results") {
    return next;
  }

  applyPlayerInput(next.player, input);
  integratePlayer(next.player);

  if (next.phase === "damage_phase" || next.phase === "launch_window") {
    const kinetic = next.phase === "launch_window" && next.kineticBatEquipped && !!input.attack;
    tryPlayerHits(next, kinetic);
    if (!kinetic) {
      tryPlayerHits(next, false);
    }
  }

  integrateDummy(next);
  advancePhase(next);

  return next;
}

export function resetDerbyForRetry(state: ImpactDummyDerbyState): ImpactDummyDerbyState {
  const fresh = createInitialDerbyState(state.seed, state.bestScore);
  fresh.phase = "countdown";
  fresh.phaseFrame = 0;
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
    state.distance,
    state.score,
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
