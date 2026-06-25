import type { Hitbox, Hurtbox, PlayerState } from "./types.js";
import {
  ATTACK_FRAMES,
  ATTACK_HITBOX_H,
  ATTACK_HITBOX_W,
  DODGE_FRAMES,
  FP_SCALE,
  HURTBOX_H,
  HURTBOX_W,
  SPECIAL_FRAMES,
  SPECIAL_HITBOX_H,
  SPECIAL_HITBOX_W,
} from "./constants.js";
import { getCharacter } from "./characters.js";

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
  const char = getCharacter(player.characterId);

  if (player.actionState === "attacking" && player.actionFrame <= ATTACK_FRAMES) {
    const offsetX = player.facing * (32 * FP_SCALE);
    return [
      {
        ownerId: player.id,
        x: player.x + offsetX - ATTACK_HITBOX_W / 2,
        y: player.y - (48 * FP_SCALE),
        w: ATTACK_HITBOX_W,
        h: ATTACK_HITBOX_H,
        damage: char.attackDamage,
        knockbackX: (4 * FP_SCALE * player.facing) / 10,
        knockbackY: -(3 * FP_SCALE) / 10,
        active: true,
      },
    ];
  }

  if (player.actionState === "special" && player.actionFrame <= SPECIAL_FRAMES) {
    const offsetX = player.facing * (48 * FP_SCALE);
    return [
      {
        ownerId: player.id,
        x: player.x + offsetX - SPECIAL_HITBOX_W / 2,
        y: player.y - (56 * FP_SCALE),
        w: SPECIAL_HITBOX_W,
        h: SPECIAL_HITBOX_H,
        damage: char.specialDamage,
        knockbackX: (8 * FP_SCALE * player.facing) / 10,
        knockbackY: -(5 * FP_SCALE) / 10,
        active: true,
      },
    ];
  }

  if (player.actionState === "dodging" && player.actionFrame <= DODGE_FRAMES) {
    return [];
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
