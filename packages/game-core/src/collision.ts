import type { Hitbox, Hurtbox, PlayerState } from "./types.js";
import {
  ATTACK_HITBOX_H,
  ATTACK_HITBOX_W,
  FP_SCALE,
  HURTBOX_H,
  HURTBOX_W,
  SPECIAL_HITBOX_H,
  SPECIAL_HITBOX_W,
} from "./constants.js";
import { isInActive } from "./frameData.js";
import { NEUTRAL_ATTACK, SPECIAL_ATTACK } from "./frameData.js";
import { getMoveDataForAction } from "./moves.js";
import { scaleKnockback } from "./feel.js";

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
  return {
    ownerId: player.id,
    x: player.x - HURTBOX_W / 2,
    y: player.y - HURTBOX_H,
    w: HURTBOX_W,
    h: HURTBOX_H,
  };
}

export function getActiveHitboxes(player: PlayerState): Hitbox[] {
  if (player.actionState === "attacking") {
    if (!isInActive(NEUTRAL_ATTACK, player.actionFrame)) return [];
    const kb = scaleKnockback(NEUTRAL_ATTACK, 0);
    const offsetX = player.facing * (32 * FP_SCALE);
    return [
      {
        ownerId: player.id,
        x: player.x + offsetX - ATTACK_HITBOX_W / 2,
        y: player.y - (48 * FP_SCALE),
        w: ATTACK_HITBOX_W,
        h: ATTACK_HITBOX_H,
        damage: NEUTRAL_ATTACK.damage,
        knockbackX: (kb.kbX * player.facing) / FP_SCALE,
        knockbackY: kb.kbY / FP_SCALE,
        active: true,
      },
    ];
  }

  if (player.actionState === "special") {
    if (!isInActive(SPECIAL_ATTACK, player.actionFrame)) return [];
    const kb = scaleKnockback(SPECIAL_ATTACK, 0);
    const offsetX = player.facing * (48 * FP_SCALE);
    return [
      {
        ownerId: player.id,
        x: player.x + offsetX - SPECIAL_HITBOX_W / 2,
        y: player.y - (56 * FP_SCALE),
        w: SPECIAL_HITBOX_W,
        h: SPECIAL_HITBOX_H,
        damage: SPECIAL_ATTACK.damage,
        knockbackX: (kb.kbX * player.facing) / FP_SCALE,
        knockbackY: kb.kbY / FP_SCALE,
        active: true,
      },
    ];
  }

  return [];
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

export { getMoveDataForAction };
