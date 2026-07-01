import type { GameState, PlayerState } from "../types.js";
import { FP_SCALE } from "../constants.js";
import { isInActive } from "../frameData.js";
import { getCombatMoveData } from "../moves/combatMoveData.js";
import { combatMoveToFrameData } from "../moves/combatMoveData.js";
import {
  fighterSpawnsProjectileOnMove,
  getProjectileStatsForMove,
} from "../moves/fighterMoveTuning.js";
import { createEnergyAttack } from "./projectiles.js";
import type { MoveDefinition } from "../moves/universalMoveSchema.js";
import { boxesOverlap, getHurtbox } from "../collision.js";
import { resolveHitFromContact } from "./hitResolution.js";
import type { InputFrame } from "../types.js";

function stubMoveDef(player: PlayerState, moveId: string): MoveDefinition {
  const data = getCombatMoveData(moveId);
  return {
    id: moveId,
    fighterId: player.characterId,
    slot: "neutralSpecial",
    displayName: moveId,
    category: "special",
    startupFrames: data?.startup ?? 8,
    activeFrames: data?.active ?? 4,
    recoveryFrames: data?.recovery ?? 18,
    damage: data?.damage ?? 8,
    baseKnockback: data?.baseKnockback ?? 10,
    knockbackGrowth: data?.knockbackGrowth ?? 1.2,
    launchAngleDeg: data?.angleDeg ?? 25,
    hitboxShape: "orb",
    hitboxWidth: 32,
    hitboxHeight: 32,
    skillFloor: "beginner",
    skillCeiling: "medium",
    tags: [],
    vfxStyle: player.characterId,
    animationKey: moveId,
    energyKind: "orb",
    energyPower: 60,
    clashable: false,
  };
}

export function maybeSpawnFighterProjectile(
  state: GameState,
  player: PlayerState,
  moveId: string,
  actionFrame: number,
): void {
  if (!fighterSpawnsProjectileOnMove(player.characterId, moveId)) return;
  const move = getCombatMoveData(moveId);
  if (!move) return;
  if (!isInActive(combatMoveToFrameData(move), actionFrame)) return;
  if (actionFrame !== move.startup) return;

  const stats = getProjectileStatsForMove(player.characterId, moveId);
  if (!stats) return;

  const def = stubMoveDef(player, moveId);
  const attack = createEnergyAttack(player, def, player.facing);
  attack.power = stats.damage;
  attack.stability = stats.knockback;
  attack.clashable = false;
  attack.durationFrames = 45;
  attack.vx = player.facing * 8 * FP_SCALE;
  state.energyAttacks = state.energyAttacks ?? [];
  const existing = state.energyAttacks.some(
    (a) => a.ownerPlayerId === player.id && a.moveId === moveId && a.frame < 5,
  );
  if (!existing) state.energyAttacks.push(attack);
}

export function resolveProjectileHits(state: GameState, inputs?: InputFrame[]): void {
  const attacks = state.energyAttacks ?? [];
  if (!attacks.length) return;

  const inputByPlayer = new Map<number, InputFrame>();
  if (inputs) for (const i of inputs) inputByPlayer.set(i.playerId, i);

  for (const attack of attacks) {
    if (attack.clashable) continue;
    if (attack.frame < 1) continue;
    const attacker = state.players[attack.ownerPlayerId];
    if (!attacker) continue;

    const hitbox = {
      x: attack.x - attack.width / 2,
      y: attack.y - attack.height / 2,
      w: attack.width,
      h: attack.height,
    };

    for (const defender of state.players) {
      if (defender.id === attack.ownerPlayerId) continue;
      if (defender.actionState === "defeated") continue;
      const hurt = getHurtbox(defender);
      if (!boxesOverlap(hitbox, hurt)) continue;

      const evt = resolveHitFromContact(
        state,
        attacker,
        defender,
        attack.power,
        0,
        0,
        attack.moveId,
        inputByPlayer.get(defender.id),
      );
      if (evt) {
        attack.durationFrames = 0;
        break;
      }
    }
  }
}
