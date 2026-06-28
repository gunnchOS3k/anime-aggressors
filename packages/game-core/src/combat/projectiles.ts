import type { MoveDefinition } from "../moves/universalMoveSchema.js";
import type { PlayerState } from "../types.js";
import { FP_SCALE } from "../constants.js";
import type { EnergyAttackKind, EnergyAttackState, EnergyElement } from "./beamTypes.js";

let nextAttackId = 1;

export function resetProjectileIdCounter(seed = 1): void {
  nextAttackId = seed;
}

const COLOR_TO_ELEMENT: Record<string, EnergyElement> = {
  red: "flame",
  orange: "impact",
  yellow: "volt",
  green: "gale",
  blue: "frost",
  indigo: "gravity",
  violet: "void",
};

export function elementFromFighterColor(color: string): EnergyElement {
  return COLOR_TO_ELEMENT[color] ?? "flame";
}

export function createEnergyAttack(
  player: PlayerState,
  move: MoveDefinition,
  facing: 1 | -1,
): EnergyAttackState {
  const kind = (move.energyKind ?? "beam") as EnergyAttackKind;
  const power = move.energyPower ?? 80;
  return {
    id: `ea-${nextAttackId++}`,
    ownerPlayerId: player.id,
    fighterId: move.fighterId,
    moveId: move.id,
    kind,
    x: player.x + facing * 40 * FP_SCALE,
    y: player.y - 30 * FP_SCALE,
    vx: facing * 6 * FP_SCALE,
    vy: 0,
    width: move.hitboxWidth * FP_SCALE,
    height: move.hitboxHeight * FP_SCALE,
    power,
    stability: power * 0.8,
    durationFrames: move.activeFrames + 30,
    element: elementFromFighterColor(player.fighterColor),
    clashable: move.clashable ?? false,
    facing,
    frame: 0,
  };
}

export function energyAttacksOverlap(a: EnergyAttackState, b: EnergyAttackState): boolean {
  if (a.ownerPlayerId === b.ownerPlayerId) return false;
  if (!a.clashable || !b.clashable) return false;
  if (a.lockedInClashId || b.lockedInClashId) return false;
  const dx = Math.abs(a.x - b.x);
  const dy = Math.abs(a.y - b.y);
  const hw = (a.width + b.width) / 2;
  const hh = (a.height + b.height) / 2;
  return dx < hw && dy < hh && a.facing !== b.facing;
}

export function tickEnergyAttack(attack: EnergyAttackState): void {
  if (attack.lockedInClashId) return;
  attack.frame += 1;
  attack.x += attack.vx;
  attack.y += attack.vy;
  attack.durationFrames -= 1;
}

export function serializeEnergyAttack(a: EnergyAttackState): string {
  return JSON.stringify(a);
}

export function deserializeEnergyAttack(json: string): EnergyAttackState {
  return JSON.parse(json) as EnergyAttackState;
}
