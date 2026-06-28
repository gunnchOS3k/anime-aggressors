import type { InputFrame } from "../types.js";
import type { GameState } from "../types.js";
import type { EnergyAttackState, EnergyClashState } from "./beamTypes.js";
import {
  CLASH_MAX_DURATION,
  CLASH_WIN_THRESHOLD,
  elementAdvantageBonus,
} from "./beamTypes.js";
import { createEnergyAttack, energyAttacksOverlap, tickEnergyAttack } from "./projectiles.js";
import { getFighterMove } from "../moves/moveDefinitions.js";
import type { MoveDefinition } from "../moves/universalMoveSchema.js";

let nextClashId = 1;

export function resetClashIdCounter(seed = 1): void {
  nextClashId = seed;
}

export function detectEnergyClashes(state: GameState): void {
  const attacks = state.energyAttacks ?? [];
  for (let i = 0; i < attacks.length; i++) {
    for (let j = i + 1; j < attacks.length; j++) {
      const a = attacks[i]!;
      const b = attacks[j]!;
      if (energyAttacksOverlap(a, b)) {
        startEnergyClash(state, a, b);
        return;
      }
    }
  }
}

function startEnergyClash(state: GameState, a: EnergyAttackState, b: EnergyAttackState): void {
  const clash: EnergyClashState = {
    id: `ec-${nextClashId++}`,
    attackAId: a.id,
    attackBId: b.id,
    playerAId: a.ownerPlayerId,
    playerBId: b.ownerPlayerId,
    x: (a.x + b.x) / 2,
    y: (a.y + b.y) / 2,
    balance: 0,
    intensity: (a.power + b.power) / 2,
    durationFrames: 0,
    maxDurationFrames: CLASH_MAX_DURATION,
    phase: "starting",
  };
  a.lockedInClashId = clash.id;
  b.lockedInClashId = clash.id;
  a.vx = 0;
  b.vx = 0;
  state.energyClashes = state.energyClashes ?? [];
  state.energyClashes.push(clash);
}

export type ClashInputBonus = {
  holdBonus: number;
  pressBonus: number;
  chargeBonus: number;
};

export function computeClashPush(
  attack: EnergyAttackState,
  input: InputFrame | undefined,
  playerDamage: number,
): ClashInputBonus {
  const holdBonus = input?.special || input?.attack ? 12 : 0;
  const pressBonus = input?.attack ? 6 : 0;
  const chargeBonus = Math.min(20, Math.floor(playerDamage / 10));
  return { holdBonus, pressBonus, chargeBonus };
}

export function tickEnergyClashes(state: GameState, inputs: InputFrame[]): void {
  const clashes = state.energyClashes ?? [];
  const attacks = state.energyAttacks ?? [];
  const attackMap = new Map(attacks.map((a) => [a.id, a]));

  for (const clash of clashes) {
    if (clash.phase === "resolved") continue;

    if (clash.phase === "starting") {
      clash.phase = "struggling";
    }

    const attackA = attackMap.get(clash.attackAId);
    const attackB = attackMap.get(clash.attackBId);
    if (!attackA || !attackB) {
      clash.phase = "resolved";
      clash.neutralBurst = true;
      continue;
    }

    const inputA = inputs.find((i) => i.playerId === clash.playerAId);
    const inputB = inputs.find((i) => i.playerId === clash.playerBId);
    const playerA = state.players[clash.playerAId];
    const playerB = state.players[clash.playerBId];

    const pushA = computeClashPush(attackA, inputA, playerA?.damage ?? 0);
    const pushB = computeClashPush(attackB, inputB, playerB?.damage ?? 0);

    let delta =
      attackA.power +
      pushA.holdBonus +
      pushA.pressBonus +
      pushA.chargeBonus +
      elementAdvantageBonus(attackA.element, attackB.element) -
      (attackB.power + pushB.holdBonus + pushB.pressBonus + pushB.chargeBonus);

    delta -= (attackA.stability - attackB.stability) * 0.05;
    clash.balance += delta * 0.15;
    clash.durationFrames += 1;
    clash.intensity = Math.min(100, clash.intensity + 0.5);

    if (clash.balance <= -CLASH_WIN_THRESHOLD) {
      resolveClash(state, clash, clash.playerAId, attackA, attackB);
    } else if (clash.balance >= CLASH_WIN_THRESHOLD) {
      resolveClash(state, clash, clash.playerBId, attackB, attackA);
    } else if (clash.durationFrames >= clash.maxDurationFrames) {
      clash.phase = "resolved";
      clash.neutralBurst = true;
      releaseClashAttacks(attackA, attackB);
    }
  }

  state.energyClashes = clashes.filter((c) => c.phase !== "resolved" || c.durationFrames < 30);
}

function resolveClash(
  state: GameState,
  clash: EnergyClashState,
  winnerId: number,
  winnerAttack: EnergyAttackState,
  loserAttack: EnergyAttackState,
): void {
  clash.phase = "resolved";
  clash.winnerPlayerId = winnerId;
  loserAttack.durationFrames = 0;
  winnerAttack.lockedInClashId = undefined;
  winnerAttack.vx = winnerAttack.facing * 10 * 256;
  state.hitstopFrames = Math.max(state.hitstopFrames, 8);
}

function releaseClashAttacks(a: EnergyAttackState, b: EnergyAttackState): void {
  a.lockedInClashId = undefined;
  b.lockedInClashId = undefined;
  a.durationFrames = 0;
  b.durationFrames = 0;
}

export function tickEnergyAttacks(state: GameState): void {
  const attacks = state.energyAttacks ?? [];
  for (const a of attacks) {
    tickEnergyAttack(a);
  }
  state.energyAttacks = attacks.filter((a) => a.durationFrames > 0);
}

export function maybeSpawnSuperEnergyAttack(
  state: GameState,
  playerId: number,
  fighterId: string,
  move: MoveDefinition,
  actionFrame: number,
): void {
  if (!move.clashable || move.slot !== "super") return;
  if (actionFrame !== move.startupFrames) return;
  const player = state.players[playerId];
  if (!player) return;
  const attack = createEnergyAttack(player, move, player.facing);
  state.energyAttacks = state.energyAttacks ?? [];
  state.energyAttacks.push(attack);
}

export function getActiveClash(state: GameState): EnergyClashState | undefined {
  return (state.energyClashes ?? []).find((c) => c.phase === "struggling" || c.phase === "starting");
}

export function serializeEnergyClash(c: EnergyClashState): string {
  return JSON.stringify(c);
}

export function deserializeEnergyClash(json: string): EnergyClashState {
  return JSON.parse(json) as EnergyClashState;
}
