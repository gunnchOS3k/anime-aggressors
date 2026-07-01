import type { GameState, InputFrame, PlayerState } from "../types.js";
import { FP_SCALE, STAGE_WIDTH } from "../constants.js";
import { getStageLayout } from "../stageLayouts.js";
import { getStage } from "../stages.js";
import { isOutsideBlastZone } from "../combat/blastZones.js";

export type CpuDifficulty = 1 | 2 | 3;

export type VersusCpuConfig = {
  playerId: number;
  difficulty: CpuDifficulty;
  seed: number;
};

function seededRand(seed: number, frame: number, salt: number): number {
  let h = (seed ^ frame ^ salt) >>> 0;
  h = Math.imul(h ^ (h >>> 16), 2246822519);
  h = Math.imul(h ^ (h >>> 13), 3266489917);
  return ((h ^ (h >>> 16)) >>> 0) / 0xffffffff;
}

function nearestOpponent(state: GameState, cpu: PlayerState): PlayerState | undefined {
  let best: PlayerState | undefined;
  let bestDist = Infinity;
  for (const p of state.players) {
    if (p.id === cpu.id || p.actionState === "defeated") continue;
    const d = Math.abs(p.x - cpu.x);
    if (d < bestDist) {
      bestDist = d;
      best = p;
    }
  }
  return best;
}

function onStageFloor(cpu: PlayerState, state: GameState): boolean {
  const stage = getStage(state.config.stageId);
  const layout = getStageLayout(stage.layoutId ?? stage.id);
  const main = layout.platforms.find((p) => p.id === layout.mainPlatformId);
  if (!main) return cpu.onGround;
  return cpu.x >= main.x - 40 * FP_SCALE && cpu.x <= main.x + main.width + 40 * FP_SCALE;
}

/** Deterministic CPU input from GameState — never mutates state directly. */
export function generateVersusCpuInput(
  state: GameState,
  config: VersusCpuConfig,
): InputFrame {
  const cpu = state.players[config.playerId];
  const frame = state.frame;
  const base: InputFrame = {
    frame,
    playerId: config.playerId,
    left: false,
    right: false,
    up: false,
    down: false,
    jump: false,
    attack: false,
    special: false,
    shield: false,
    dodge: false,
    grab: false,
  };

  if (!cpu || cpu.actionState === "defeated") return base;

  const opp = nearestOpponent(state, cpu);
  if (!opp) return base;

  const dist = Math.abs(opp.x - cpu.x);
  const inRange = dist < 55 * FP_SCALE;
  const offstage = !cpu.onGround && cpu.y > getStage(state.config.stageId).bounds.floorY + 80 * FP_SCALE;
  const blastRisk = isOutsideBlastZone(cpu) || cpu.y > getStage(state.config.stageId).bounds.floorY + 200 * FP_SCALE;
  const r = (salt: number) => seededRand(config.seed, frame, salt + config.difficulty * 97);

  if (offstage || blastRisk) {
    base.up = true;
    base.jump = frame % 18 < 10;
    if (opp.x > cpu.x) base.right = true;
    else base.left = true;
    if (config.difficulty >= 2) base.special = frame % 40 < 8;
    return base;
  }

  if (cpu.actionState === "hitstun" || cpu.shieldStunFrames > 0) {
    return base;
  }

  const towardRight = opp.x > cpu.x;
  if (towardRight) base.right = true;
  else base.left = true;

  if (!cpu.onGround && cpu.vy > 0) {
    if (config.difficulty >= 2 && r(3) > 0.7) base.down = true;
  }

  if (cpu.onGround && !onStageFloor(cpu, state)) {
    base.jump = true;
    if (cpu.x < STAGE_WIDTH / 2) base.right = true;
    else base.left = true;
    return base;
  }

  const attackChance = config.difficulty === 1 ? 0.12 : config.difficulty === 2 ? 0.22 : 0.32;
  const shieldChance = config.difficulty === 1 ? 0.02 : config.difficulty === 2 ? 0.08 : 0.14;
  const dodgeChance = config.difficulty === 1 ? 0.01 : config.difficulty === 2 ? 0.05 : 0.1;

  if (inRange && (r(1) < attackChance || (dist < 40 * FP_SCALE && frame % 6 < 3))) {
    base.attack = true;
    if (config.difficulty >= 3 && r(9) > 0.5) {
      if (towardRight) base.right = true;
      else base.left = true;
    }
  } else if (inRange && r(2) < shieldChance && cpu.onGround) {
    base.shield = true;
  } else if (inRange && r(4) < dodgeChance) {
    base.dodge = true;
    base.attack = false;
    base.shield = false;
  }

  if (!inRange && cpu.onGround && r(5) < (config.difficulty === 1 ? 0.03 : 0.07)) {
    base.jump = true;
  }

  if (config.difficulty >= 2 && !inRange && dist > 90 * FP_SCALE && r(6) < 0.05) {
    base.special = true;
  }

  return base;
}

export function mergeCpuInputs(
  state: GameState,
  humanInputs: InputFrame[],
  cpuConfigs: VersusCpuConfig[],
): InputFrame[] {
  const byPlayer = new Map<number, InputFrame>();
  for (const input of humanInputs) byPlayer.set(input.playerId, input);
  for (const cfg of cpuConfigs) {
    byPlayer.set(cfg.playerId, generateVersusCpuInput(state, cfg));
  }
  return [...byPlayer.values()].sort((a, b) => a.playerId - b.playerId);
}

export function cpuActionFrequency(input: InputFrame): number {
  return [
    input.attack,
    input.special,
    input.shield,
    input.dodge,
    input.jump,
    input.grab,
  ].filter(Boolean).length;
}
