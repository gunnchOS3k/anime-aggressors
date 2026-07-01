import type { Hitbox, Hurtbox, PlayerState } from "./types.js";
import { FP_SCALE, HURTBOX_H, HURTBOX_W } from "./constants.js";
import { isInActive } from "./frameData.js";
import { getCombatMoveData } from "./moves/combatMoveData.js";
import { combatMoveToFrameData } from "./moves/combatMoveData.js";
import { scaledHitDamage } from "./fighterCreation.js";
import { scaledHurtboxDimension } from "./fighterCreation.js";
import { applyStaleMultiplier } from "./combat/staleMoves.js";
import { applyFighterMoveOverrides } from "./moves/fighterMoveTuning.js";
import { computeKnockback } from "./combat/knockback.js";
import { getCharacterForPlayer } from "./characters.js";

export function getHurtboxes(players: PlayerState[]): Hurtbox[] {
  return players
    .filter((p) => p.actionState !== "defeated" && p.invulnFrames <= 0)
    .map(getHurtbox);
}

export function getActiveHitboxesForState(players: PlayerState[]): Hitbox[] {
  const boxes: Hitbox[] = [];
  for (const p of players) {
    boxes.push(...getActiveHitboxes(p));
  }
  return boxes;
}

export function getHurtbox(player: PlayerState): Hurtbox {
  const w = scaledHurtboxDimension(HURTBOX_W, player);
  const h = scaledHurtboxDimension(HURTBOX_H, player);
  return {
    ownerId: player.id,
    x: player.x - w / 2,
    y: player.y - h,
    w,
    h,
  };
}

export function getGrabHitbox(player: PlayerState): Hitbox | null {
  if (player.actionState !== "grabbing") return null;
  const move = getCombatMoveData("grab");
  if (!move) return null;
  const frameData = combatMoveToFrameData(move);
  if (!isInActive(frameData, player.actionFrame)) return null;
  const w = move.hitboxWidth * FP_SCALE;
  const h = move.hitboxHeight * FP_SCALE;
  const ox = move.hitboxOffsetX * FP_SCALE * player.facing;
  const oy = move.hitboxOffsetY * FP_SCALE;
  return {
    ownerId: player.id,
    x: player.x + ox - w / 2,
    y: player.y - oy - h / 2,
    w,
    h,
    damage: 0,
    knockbackX: 0,
    knockbackY: 0,
    active: true,
  };
}

export function getActiveHitboxes(player: PlayerState): Hitbox[] {
  if (player.actionState !== "attacking" && player.actionState !== "special") return [];

  const moveId =
    player.currentMoveId && player.currentMoveId !== "none"
      ? player.currentMoveId
      : player.actionState === "special"
        ? "special_attack"
        : "neutral_attack";
  let move = getCombatMoveData(moveId);
  if (!move) return [];
  move = applyFighterMoveOverrides(player.characterId, moveId, move);

  const frameData = combatMoveToFrameData(move);
  if (!isInActive(frameData, player.actionFrame)) return [];

  const staleMult = applyStaleMultiplier(player, moveId);
  const damage = Math.max(1, Math.floor(scaledHitDamage(move.damage, player) * staleMult));
  const char = getCharacterForPlayer(player);
  const kb = computeKnockback({
    moveDamage: damage,
    baseKnockback: move.baseKnockback * staleMult,
    knockbackGrowth: move.knockbackGrowth,
    victimDamagePercent: 0,
    victimWeight: char.weight,
    launchRatio: 1,
    hitStrength: "light",
    angleDeg: move.angleDeg,
  });

  const w = move.hitboxWidth * FP_SCALE;
  const h = move.hitboxHeight * FP_SCALE;
  const ox =
    move.category === "backAir"
      ? -Math.abs(move.hitboxOffsetX) * FP_SCALE * player.facing
      : move.hitboxOffsetX * FP_SCALE * player.facing;
  const oy = move.hitboxOffsetY * FP_SCALE;

  return [
    {
      ownerId: player.id,
      x: player.x + ox - w / 2,
      y: player.y - oy - h / 2,
      w,
      h,
      damage,
      knockbackX: (kb.vx * player.facing) / FP_SCALE,
      knockbackY: kb.vy / FP_SCALE,
      active: true,
    },
  ];
}

export function boxesOverlap(
  a: { x: number; y: number; w: number; h: number },
  b: { x: number; y: number; w: number; h: number },
): boolean {
  return (
    a.x < b.x + b.w &&
    a.x + a.w > b.x &&
    a.y < b.y + b.h &&
    a.y + a.h > b.y
  );
}
