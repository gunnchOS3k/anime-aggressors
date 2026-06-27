import type { CreatedFighter } from "../createdFighter.js";
import type { ImpactDummyDerbyState } from "./impactDummyDerbyTypes.js";
import { ELEMENTS } from "../elements.js";
import { FP_SCALE, SIM_HZ } from "../constants.js";

export function comboWindowForFighter(fighter: CreatedFighter): number {
  switch (fighter.size) {
    case "small":
      return 50;
    case "large":
      return 35;
    default:
      return 42;
  }
}

export function launchPowerScaleForFighter(fighter: CreatedFighter): number {
  switch (fighter.size) {
    case "small":
      return 0.88;
    case "large":
      return 1.18;
    default:
      return 1.0;
  }
}

export function attackRecoveryFrames(fighter: CreatedFighter): number {
  const effect = ELEMENTS[fighter.color].effect;
  if (effect === "shock") return 10;
  return 14;
}

export function onDerbyHit(state: ImpactDummyDerbyState, baseDamage: number): number {
  const effect = ELEMENTS[state.fighter.color].effect;
  let damage = baseDamage;

  switch (effect) {
    case "burn":
      state.dummy.burnTicksRemaining = 90;
      break;
    case "armorBreak":
      damage = Math.floor(damage * 1.12);
      break;
    case "shock":
      state.dummy.hitstunFrames = Math.max(state.dummy.hitstunFrames, 10);
      break;
    case "slow":
      state.dummy.slowFramesRemaining = 45;
      state.dummy.slowMultiplierFp = 75;
      break;
    case "pull":
      state.dummy.vx = Math.floor(state.dummy.vx * 0.5);
      break;
    case "phase":
      state.player.x += state.player.facing * Math.floor(FP_SCALE * 0.15);
      break;
    case "wind":
      break;
    default:
      break;
  }

  return damage;
}

export function tickDerbyElements(state: ImpactDummyDerbyState): void {
  const d = state.dummy;
  if (d.burnTicksRemaining > 0) {
    d.burnTicksRemaining -= 1;
    if (state.frame % 30 === 0 && state.phase === "damage") {
      d.damage += 1;
      state.totalDamageDealt += 1;
    }
  }
  if (d.slowFramesRemaining > 0) {
    d.slowFramesRemaining -= 1;
    if (d.slowFramesRemaining === 0) d.slowMultiplierFp = 100;
  }
}

export function launchAngleModifiers(
  fighter: CreatedFighter,
  inputUp: boolean,
  inputDown: boolean,
): { vxScale: number; vyScale: number } {
  const effect = ELEMENTS[fighter.color].effect;
  let vxScale = 1;
  let vyScale = 1;

  if (inputUp) {
    vyScale = 1.35;
    vxScale = 0.85;
  } else if (inputDown) {
    vyScale = 0.65;
    vxScale = 1.2;
  }

  if (effect === "wind") {
    vxScale *= 1.08;
    vyScale *= 1.05;
  }

  return { vxScale, vyScale };
}

export function dummyVelocityScale(state: ImpactDummyDerbyState): number {
  if (state.dummy.slowFramesRemaining > 0) {
    return state.dummy.slowMultiplierFp / 100;
  }
  return 1;
}

export function barrierKnockbackDamping(state: ImpactDummyDerbyState): number {
  const effect = ELEMENTS[state.fighter.color].effect;
  if (effect === "pull") return 0.55;
  return 0.72;
}

export function batLaunchBonus(fighter: CreatedFighter): number {
  const effect = ELEMENTS[fighter.color].effect;
  if (effect === "armorBreak") return 1.15;
  return 1.0;
}

export const GRAVITY = (12 * FP_SCALE) / SIM_HZ;
