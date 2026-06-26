import type { PlayerState } from "./types.js";
import type { MoveFrameData } from "./frameData.js";
import { FP_SCALE } from "./constants.js";
import { isInRecovery } from "./frameData.js";

export type FighterColor =
  | "red"
  | "orange"
  | "yellow"
  | "green"
  | "blue"
  | "indigo"
  | "violet";

export type ElementEffect =
  | "burn"
  | "armorBreak"
  | "shock"
  | "wind"
  | "slow"
  | "pull"
  | "phase";

export type ElementDef = {
  name: string;
  effect: ElementEffect;
  description: string;
  hexColor: string;
};

export const ELEMENTS: Record<FighterColor, ElementDef> = {
  red: {
    name: "Flame",
    effect: "burn",
    description: "Adds small burn damage after confirmed hits.",
    hexColor: "#e63946",
  },
  orange: {
    name: "Impact",
    effect: "armorBreak",
    description: "Adds extra shield pressure and heavier final-hit impact.",
    hexColor: "#f77f00",
  },
  yellow: {
    name: "Volt",
    effect: "shock",
    description: "Adds brief stun sparks and faster-feeling hit confirms.",
    hexColor: "#ffd60a",
  },
  green: {
    name: "Gale",
    effect: "wind",
    description: "Adds drift, pushback, and air-control flavor.",
    hexColor: "#2dc653",
  },
  blue: {
    name: "Frost",
    effect: "slow",
    description: "Adds small movement slow on clean hits.",
    hexColor: "#4cc9f0",
  },
  indigo: {
    name: "Gravity",
    effect: "pull",
    description: "Slightly pulls opponents inward during combo hits.",
    hexColor: "#5a189a",
  },
  violet: {
    name: "Void",
    effect: "phase",
    description: "Adds tricky displacement on specials.",
    hexColor: "#9d4edd",
  },
};

export const BURN_TICKS = 90;
export const BURN_DAMAGE_PER_TICK = 15; // fixed-point damage per 30 frames (~1.5%/sec at 60hz scaled)
export const SLOW_DURATION_FRAMES = 45;
export const SLOW_MULTIPLIER_FP = 92; // percent
export const COMBO_PULL_STRENGTH_FP = 8; // percent of FP_SCALE pull per hit

export function getElementForColor(color: FighterColor): ElementDef {
  return ELEMENTS[color];
}

export function getElementColorHex(color: FighterColor): string {
  return ELEMENTS[color].hexColor;
}

export function applyElementOnHit(
  attacker: PlayerState,
  defender: PlayerState,
  moveData: MoveFrameData,
  attackerActionFrame: number,
): void {
  const effect = attacker.elementEffect;
  if (!effect) return;

  switch (effect) {
    case "burn":
      defender.burnFramesRemaining = BURN_TICKS;
      break;
    case "armorBreak":
      if (defender.actionState === "shielding") {
        defender.shieldHealth -= Math.floor(moveData.damage * 0.15);
      }
      if (isInRecovery(moveData, attackerActionFrame)) {
        defender.vx += attacker.facing * Math.floor(FP_SCALE * 0.08);
      }
      break;
    case "shock":
      if (attacker.actionFrame > 0) {
        attacker.actionFrame = Math.max(0, attacker.actionFrame - 2);
      }
      if (defender.hitstunFrames > 0) {
        defender.hitstunFrames += 1;
      }
      break;
    case "wind":
      defender.vx += attacker.facing * Math.floor((FP_SCALE * 11) / 100);
      attacker.airDriftBonusFrames = 20;
      break;
    case "slow":
      defender.slowFramesRemaining = SLOW_DURATION_FRAMES;
      defender.slowMultiplierFp = SLOW_MULTIPLIER_FP;
      break;
    case "pull":
      if (!isInRecovery(moveData, attackerActionFrame)) {
        const pull = Math.floor((FP_SCALE * COMBO_PULL_STRENGTH_FP) / 100);
        defender.x += attacker.facing > 0 ? pull : -pull;
      }
      break;
    case "phase":
      if (attacker.actionState === "special") {
        attacker.x += attacker.facing * Math.floor(FP_SCALE * 0.04);
        attacker.invulnFrames = Math.max(attacker.invulnFrames, 4);
      }
      break;
  }
}

export function tickElementalEffects(player: PlayerState): void {
  if (player.burnFramesRemaining > 0) {
    player.burnFramesRemaining -= 1;
    if (player.burnFramesRemaining % 30 === 0) {
      player.damage += 1;
    }
  }

  if (player.slowFramesRemaining > 0) {
    player.slowFramesRemaining -= 1;
    if (player.slowFramesRemaining <= 0) {
      player.slowMultiplierFp = 100;
    }
  }

  if (player.airDriftBonusFrames > 0) {
    player.airDriftBonusFrames -= 1;
  }
}

export function getMovementSlowMultiplier(player: PlayerState): number {
  if (player.slowFramesRemaining > 0) {
    return player.slowMultiplierFp / 100;
  }
  return 1;
}
