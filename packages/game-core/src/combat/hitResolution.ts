import type { GameState, PlayerState } from "../types.js";
import { FP_SCALE, HITSTUN_BASE } from "../constants.js";
import { getCharacterForPlayer } from "../characters.js";
import { boxesOverlap, getActiveHitboxes, getHurtbox } from "../collision.js";
import { NEUTRAL_ATTACK, SPECIAL_ATTACK } from "../frameData.js";
import { getMoveData, type MoveId } from "../moves.js";
import { scaledHitDamage, scaledKnockbackTaken } from "../fighterCreation.js";
import { applyElementOnHit } from "../elements.js";
import { applyAuraHitPenalty } from "../aura/auraCharge.js";
import { elementGameplayEnabled } from "../rulesets.js";
import { classifyHitStrength, cameraImpulseForStrength } from "./combatTuning.js";
import { computeKnockback } from "./knockback.js";
import { computeHitlag } from "./hitlag.js";
import { computeHitstun, isLaunched } from "./hitstun.js";
import { createHitEvent, type HitEvent } from "./hitEvents.js";
import { isOutsideBlastZone } from "./blastZones.js";
import { getStage } from "../stages.js";
import { createDefaultAuraState } from "../aura/auraTypes.js";

function getDamageRatio(state: GameState): number {
  return state.config.ruleset?.damageRatio ?? 1;
}

function getLaunchRatio(state: GameState): number {
  return state.config.ruleset?.launchRatio ?? 1;
}

export function resolveHitFromContact(
  state: GameState,
  attacker: PlayerState,
  defender: PlayerState,
  damage: number,
  kbX: number,
  kbY: number,
  moveId: string,
): HitEvent | null {
  if (defender.invulnFrames > 0) return null;

  if (defender.actionState === "shielding") {
    defender.shieldHealth -= damage;
    if (defender.shieldHealth <= 0) {
      defender.actionState = "hitstun";
      defender.hitstunFrames = HITSTUN_BASE * 2;
    }
    return null;
  }

  const preDamage = defender.damage;
  const strength = classifyHitStrength(damage, moveId);
  const char = getCharacterForPlayer(defender);
  const launchRatio = getLaunchRatio(state);
  const dmgRatio = getDamageRatio(state);
  const finalDamage = Math.max(1, Math.floor(scaledHitDamage(damage, attacker) * dmgRatio));

  const moveData =
    attacker.actionState === "special"
      ? getMoveData(attacker.currentMoveId as MoveId) ?? SPECIAL_ATTACK
      : getMoveData(attacker.currentMoveId as MoveId) ?? NEUTRAL_ATTACK;

  const kb = computeKnockback({
    moveDamage: finalDamage,
    baseKnockback: moveData.baseKnockback,
    knockbackGrowth: moveData.knockbackGrowth,
    victimDamagePercent: preDamage,
    victimWeight: char.weight,
    launchRatio,
    hitStrength: strength,
    angleDeg: kbY !== 0 ? -55 : attacker.facing > 0 ? -35 : -145,
  });

  let vx = kbX !== 0 ? kbX * launchRatio : (kb.vx * attacker.facing) / FP_SCALE;
  let vy = kbY !== 0 ? kbY * launchRatio : kb.vy / FP_SCALE;
  vx = scaledKnockbackTaken(Math.floor(vx * FP_SCALE), defender) / FP_SCALE;
  vy = scaledKnockbackTaken(Math.floor(vy * FP_SCALE), defender) / FP_SCALE;

  if (state.config.ruleset?.matchType === "stamina") {
    defender.staminaHp = Math.max(0, defender.staminaHp - finalDamage);
  } else {
    defender.damage += finalDamage;
  }

  defender.vx += vx;
  defender.vy += vy;
  defender.actionState = isLaunched(strength, kb.magnitude) ? "hitstun" : "hitstun";
  defender.hitstunFrames = computeHitstun(strength, defender.damage);
  defender.onGround = false;
  defender.currentMoveId = "none";
  applyAuraHitPenalty(defender, finalDamage >= 15);

  const elementMode = state.config.ruleset?.elementMode ?? "on";
  if (elementGameplayEnabled(elementMode)) {
    applyElementOnHit(attacker, defender, moveData, attacker.actionFrame);
  }

  const hitlag = computeHitlag(strength);
  if (hitlag > state.hitstopFrames) state.hitstopFrames = hitlag;

  return createHitEvent({
    frame: state.frame,
    attackerPlayerId: attacker.id,
    victimPlayerId: defender.id,
    moveId,
    damage: finalDamage,
    preHitVictimDamage: preDamage,
    postHitVictimDamage: defender.damage,
    launchAngleDeg: kbY !== 0 ? -55 : -35,
    knockbackX: vx,
    knockbackY: vy,
    hitlagFrames: hitlag,
    hitstunFrames: defender.hitstunFrames,
    hitStrength: strength,
    element: attacker.elementEffect,
    cameraImpulseKind: cameraImpulseForStrength(strength),
  });
}

export function resolveCombatHits(state: GameState): HitEvent[] {
  const events: HitEvent[] = [];
  const hitboxes = state.players.flatMap((p) => getActiveHitboxes(p));

  for (const hit of hitboxes) {
    if (!hit.active) continue;
    const attacker = state.players[hit.ownerId];
    if (!attacker) continue;

    for (const defender of state.players) {
      if (defender.id === hit.ownerId) continue;
      if (defender.actionState === "defeated") continue;

      const hurt = getHurtbox(defender);
      if (!boxesOverlap(hit, hurt)) continue;

      const moveId = attacker.currentMoveId || "neutral-attack";
      const evt = resolveHitFromContact(
        state,
        attacker,
        defender,
        hit.damage,
        hit.knockbackX,
        hit.knockbackY,
        moveId,
      );
      if (evt) events.push(evt);
    }
  }
  return events;
}

export function processBlastZoneKOs(state: GameState): boolean {
  let anyKo = false;
  for (const player of state.players) {
    if (player.actionState === "defeated") continue;
    if (!isOutsideBlastZone(player)) continue;

    anyKo = true;
    const matchType = state.config.ruleset?.matchType ?? "stock";
    if (matchType === "stamina" && player.staminaHp <= 0) {
      player.actionState = "defeated";
      continue;
    }
    for (const other of state.players) {
      if (other.id !== player.id && other.actionState !== "defeated") {
        if (matchType === "time") other.score += 1;
      }
    }
    player.stocks -= 1;
    if (player.stocks <= 0) {
      player.actionState = "defeated";
    } else {
      const stageDef = getStage(state.config.stageId);
      const spawn = stageDef.spawnPoints[player.id] ?? stageDef.spawnPoints[0];
      respawnPlayer(player, spawn, state.config.ruleset);
    }
  }
  return anyKo;
}

function respawnPlayer(
  player: PlayerState,
  spawn: { x: number; y: number },
  ruleset?: import("../rulesets.js").GameRuleset,
): void {
  player.x = spawn.x;
  player.y = spawn.y;
  player.vx = 0;
  player.vy = 0;
  player.damage = 0;
  if (ruleset?.matchType === "stamina") player.staminaHp = ruleset.staminaHp;
  player.actionState = "idle";
  player.actionFrame = 0;
  player.hitstunFrames = 0;
  player.invulnFrames = 60;
  player.coyoteFrames = 0;
  player.jumpBufferFrames = 0;
  player.fastFalling = false;
  player.currentMoveId = "none";
  player.burnFramesRemaining = 0;
  player.slowFramesRemaining = 0;
  player.slowMultiplierFp = 100;
  player.airDriftBonusFrames = 0;
  player.aura = createDefaultAuraState();
  const char = getCharacterForPlayer(player);
  player.jumpsRemaining = char.maxJumps;
  player.jumpsUsed = 0;
  player.jumpHoldFrames = 0;
  player.wasJumpHeld = false;
  player.onGround = true;
}
