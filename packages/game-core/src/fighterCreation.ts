import type { CreatedFighter } from "./createdFighter.js";
import { getDefaultCreatedFighter } from "./createdFighter.js";
import type { FighterSize } from "./sizeClasses.js";
import { getSizeStats, scaleBySize } from "./sizeClasses.js";
import type { FighterColor, ElementEffect } from "./elements.js";
import { getElementForColor, getElementColorHex } from "./elements.js";
import type { GameConfig, PlayerState } from "./types.js";
import { FP_SCALE } from "./constants.js";

export type FighterPreviewStats = {
  speed: string;
  power: string;
  weight: string;
  jump: string;
  element: string;
  passive: string;
  special: string;
};

export function getFighterProfile(
  config: GameConfig,
  playerId: number,
): CreatedFighter {
  return config.fighterProfiles?.[playerId] ?? getDefaultCreatedFighter(playerId);
}

export function applyCreatedFighterToPlayer(
  player: PlayerState,
  fighter: CreatedFighter,
): void {
  player.characterId = `created:${fighter.id}`;
  player.fighterName = fighter.name;
  player.fighterSize = fighter.size;
  player.fighterColor = fighter.color;
  player.elementEffect = fighter.element;
}

export function getPlayerSizeStats(player: PlayerState) {
  return getSizeStats(player.fighterSize ?? "medium");
}

export function getDisplayColor(player: PlayerState): string {
  if (player.fighterColor) {
    return getElementColorHex(player.fighterColor);
  }
  return player.id === 0 ? "#ff6b35" : "#4ecdc4";
}

export function getVisualScale(player: PlayerState): number {
  const stats = getPlayerSizeStats(player);
  return stats.hurtboxScale;
}

export function previewFighterStats(
  size: FighterSize,
  color: FighterColor,
): FighterPreviewStats {
  const stats = getSizeStats(size);
  const el = getElementForColor(color);
  return {
    speed: stats.speedMultiplier >= 1 ? "Fast" : stats.speedMultiplier < 1 ? "Slow" : "Balanced",
    power: stats.damageMultiplier >= 1.1 ? "Heavy" : stats.damageMultiplier < 1 ? "Light" : "Balanced",
    weight: stats.weight >= 1.1 ? "Heavy" : stats.weight < 1 ? "Light" : "Standard",
    jump: stats.jumpMultiplier >= 1 ? "High" : stats.jumpMultiplier < 1 ? "Low" : "Standard",
    element: el.name,
    passive: el.description,
    special: `${el.name} — ${el.effect}`,
  };
}

export function scaledRunSpeed(baseRun: number, player: PlayerState): number {
  const stats = getPlayerSizeStats(player);
  const slow = player.slowMultiplierFp ? player.slowMultiplierFp / 100 : 1;
  return scaleBySize(baseRun * slow, stats.speedMultiplier);
}

export function scaledJumpVelocity(baseJump: number, player: PlayerState): number {
  const stats = getPlayerSizeStats(player);
  return scaleBySize(baseJump, stats.jumpMultiplier);
}

export function scaledHitDamage(baseDamage: number, player: PlayerState): number {
  const stats = getPlayerSizeStats(player);
  return Math.max(1, scaleBySize(baseDamage, stats.damageMultiplier));
}

export function scaledKnockbackTaken(kb: number, defender: PlayerState): number {
  const stats = getPlayerSizeStats(defender);
  return scaleBySize(kb, stats.knockbackTakenMultiplier);
}

export function scaledHurtboxDimension(base: number, player: PlayerState): number {
  const stats = getPlayerSizeStats(player);
  return Math.floor(base * stats.hurtboxScale);
}

export { FP_SCALE };
