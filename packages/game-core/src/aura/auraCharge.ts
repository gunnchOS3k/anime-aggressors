import type { InputFrame, PlayerState } from "../types.js";
import {
  AURA_CHARGE_RATE,
  AURA_DECAY_RATE,
  AURA_HEAVY_HIT_LOSS,
  AURA_INTERRUPT_LOSS,
  AURA_MAX,
  AURA_OVERCHARGE_COOLDOWN,
  auraLevelFromCurrent,
  createDefaultAuraState,
  isSuperReady,
  type AuraChargeState,
} from "./auraTypes.js";

export {
  AURA_MAX,
  AURA_CHARGE_RATE,
  auraLevelFromCurrent,
  createDefaultAuraState,
  isSuperReady,
  type AuraChargeLevel,
  type AuraChargeState,
} from "./auraTypes.js";

export function initPlayerAura(player: PlayerState): void {
  player.aura = createDefaultAuraState();
}

export function syncAuraLevel(aura: AuraChargeState): void {
  aura.level = auraLevelFromCurrent(aura.current);
  aura.overcharged = aura.current >= aura.max;
}

export function tickAuraCooldown(aura: AuraChargeState): void {
  if (aura.cooldownFrames > 0) aura.cooldownFrames -= 1;
}

export function canStartAuraCharge(player: PlayerState): boolean {
  return (
    player.actionState !== "hitstun" &&
    player.actionState !== "defeated" &&
    player.aura.cooldownFrames <= 0 &&
    player.onGround
  );
}

export function startAuraCharge(player: PlayerState): void {
  player.actionState = "auraCharging";
  player.actionFrame = 0;
  player.aura.charging = true;
  player.vx = 0;
  player.currentMoveId = "aura_charge";
}

export function isAuraChargeHeld(input: InputFrame | undefined): boolean {
  if (!input) return false;
  return !!(input.auraCharge || (input.shield && input.special));
}

export function tickAuraWhileCharging(player: PlayerState, input: InputFrame | undefined): boolean {
  const aura = player.aura;
  tickAuraCooldown(aura);

  if (!isAuraChargeHeld(input)) {
    return false;
  }

  aura.current = Math.min(aura.max, aura.current + AURA_CHARGE_RATE);
  syncAuraLevel(aura);
  player.vx = Math.floor(player.vx * 0.7);
  return true;
}

export function releaseAuraCharge(player: PlayerState): "super" | "idle" {
  const aura = player.aura;
  aura.charging = false;
  player.actionFrame = 0;

  if (isSuperReady(aura)) {
    aura.current = 0;
    syncAuraLevel(aura);
    aura.cooldownFrames = AURA_OVERCHARGE_COOLDOWN;
    player.actionState = "special";
    player.currentMoveId = "super";
    return "super";
  }

  player.actionState = "idle";
  player.currentMoveId = "none";
  return "idle";
}

export function tickAuraDecay(player: PlayerState): void {
  const aura = player.aura;
  tickAuraCooldown(aura);
  if (aura.charging || aura.current <= 0) return;
  aura.current = Math.max(0, aura.current - AURA_DECAY_RATE);
  syncAuraLevel(aura);
}

export function consumeAuraOnSuper(player: PlayerState): void {
  player.aura.current = 0;
  syncAuraLevel(player.aura);
  player.aura.cooldownFrames = AURA_OVERCHARGE_COOLDOWN;
  player.aura.charging = false;
}

export function applyAuraHitPenalty(player: PlayerState, heavy: boolean): void {
  const loss = heavy ? AURA_HEAVY_HIT_LOSS : AURA_INTERRUPT_LOSS;
  player.aura.current = Math.max(0, player.aura.current - loss);
  player.aura.charging = false;
  syncAuraLevel(player.aura);
  if (player.actionState === "auraCharging") {
    player.actionState = "hitstun";
    player.currentMoveId = "none";
  }
}

export function auraClashStabilityBonus(aura: AuraChargeState): number {
  switch (aura.level) {
    case 3:
      return 8;
    case 2:
      return 4;
    case 1:
      return 2;
    default:
      return 0;
  }
}

export function auraClashPowerBonus(aura: AuraChargeState): number {
  switch (aura.level) {
    case 3:
      return 10;
    case 2:
      return 5;
    case 1:
      return 2;
    default:
      return 0;
  }
}

export function auraSpecialPowerMultiplier(aura: AuraChargeState): number {
  switch (aura.level) {
    case 3:
      return 1.15;
    case 2:
      return 1.08;
    case 1:
      return 1.03;
    default:
      return 1;
  }
}
