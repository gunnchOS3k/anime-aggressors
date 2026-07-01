import type { GameState, PlayerState } from "../types.js";
import { FP_SCALE, HITSTUN_BASE } from "../constants.js";
import { getCharacterForPlayer } from "../characters.js";
import { boxesOverlap, getActiveHitboxes, getHurtbox } from "../collision.js";
import { scaledHitDamage, scaledKnockbackTaken } from "../fighterCreation.js";
import { applyElementOnHit } from "../elements.js";
import { applyAuraHitPenalty } from "../aura/auraCharge.js";
import { elementGameplayEnabled } from "../rulesets.js";
import { classifyHitStrength, cameraImpulseForStrength } from "./combatTuning.js";
import { computeKnockback } from "./knockback.js";
import { computeHitlag } from "./hitlag.js";
import { computeHitstun } from "./hitstun.js";
import { createHitEvent, type HitEvent } from "./hitEvents.js";
import { isOutsideBlastZone } from "./blastZones.js";
import { getStage } from "../stages.js";
import { getStageLayout } from "../stageLayouts.js";
import { resetPlayerAfterRespawn } from "./playerLifecycle.js";
import { getCombatMoveData } from "../moves/combatMoveData.js";
import { combatMoveToFrameData } from "../moves/combatMoveData.js";
import { applyDirectionalInfluence } from "./di.js";
import { applyShieldHit } from "./shieldSystem.js";
import { applyStaleMultiplier, recordMoveUsed } from "./staleMoves.js";
import type { InputFrame } from "../types.js";

function getDamageRatio(state: GameState): number {
  return state.config.ruleset?.damageRatio ?? 1;
}

function getLaunchRatio(state: GameState): number {
  return state.config.ruleset?.launchRatio ?? 1;
}

function canHitVictim(
  attacker: PlayerState,
  defenderId: number,
  moveId: string,
  frame: number,
): boolean {
  const move = getCombatMoveData(moveId);
  if (!move) return !attacker.hitVictimsThisMove.includes(defenderId);

  if (move.multiHit && move.canHitSameTargetAgain) {
    const interval = move.hitIntervalFrames ?? 4;
    const contact = attacker.multiHitContacts.find((c) => c.victimId === defenderId);
    if (!contact) return true;
    return frame - contact.lastHitFrame >= interval;
  }

  if (move.multiHit) return true;
  return !attacker.hitVictimsThisMove.includes(defenderId);
}

function recordHitVictim(attacker: PlayerState, defenderId: number, frame: number, moveId: string): void {
  const move = getCombatMoveData(moveId);
  if (move?.multiHit && move.canHitSameTargetAgain) {
    const existing = attacker.multiHitContacts.find((c) => c.victimId === defenderId);
    if (existing) existing.lastHitFrame = frame;
    else attacker.multiHitContacts.push({ victimId: defenderId, lastHitFrame: frame });
    return;
  }
  if (!attacker.hitVictimsThisMove.includes(defenderId)) {
    attacker.hitVictimsThisMove.push(defenderId);
  }
}

export function resolveHitFromContact(
  state: GameState,
  attacker: PlayerState,
  defender: PlayerState,
  damage: number,
  _kbX: number,
  _kbY: number,
  moveId: string,
  defenderInput?: InputFrame,
): HitEvent | null {
  if (defender.invulnFrames > 0) return null;

  const move = getCombatMoveData(moveId);
  const moveData = move ? combatMoveToFrameData(move) : null;

  if (defender.actionState === "shielding") {
    const shieldDmg = move?.shieldDamage ?? damage;
    const shieldStun = move?.shieldStunFrames ?? 8;
    const pushback = (attacker.facing * 3 * FP_SCALE) / FP_SCALE;
    applyShieldHit(defender, shieldDmg, shieldStun, pushback);
    return null;
  }

  const preDamage = defender.damage;
  const staleMult = applyStaleMultiplier(attacker, moveId);
  const dmgRatio = getDamageRatio(state);
  const launchRatio = getLaunchRatio(state);
  const finalDamage = Math.max(1, Math.floor(scaledHitDamage(damage, attacker) * dmgRatio * staleMult));
  const strength = classifyHitStrength(finalDamage, moveId);

  const char = getCharacterForPlayer(defender);
  const angleDeg = move?.angleDeg ?? (attacker.facing > 0 ? -35 : -145);

  const kb = computeKnockback({
    moveDamage: finalDamage,
    baseKnockback: (move?.baseKnockback ?? 8) * staleMult,
    knockbackGrowth: move?.knockbackGrowth ?? 1.2,
    victimDamagePercent: preDamage,
    victimWeight: char.weight,
    launchRatio,
    hitStrength: strength,
    angleDeg,
  });

  let vx = (kb.vx * attacker.facing) / FP_SCALE;
  let vy = kb.vy / FP_SCALE;
  const influenced = applyDirectionalInfluence(vx, vy, defenderInput, strength);
  vx = influenced.vx;
  vy = influenced.vy;

  vx = scaledKnockbackTaken(Math.floor(vx * FP_SCALE), defender) / FP_SCALE;
  vy = scaledKnockbackTaken(Math.floor(vy * FP_SCALE), defender) / FP_SCALE;

  if (state.config.ruleset?.matchType === "stamina") {
    defender.staminaHp = Math.max(0, defender.staminaHp - finalDamage);
  } else {
    defender.damage += finalDamage;
  }

  defender.vx += vx;
  defender.vy += vy;
  defender.actionState = "hitstun";
  defender.hitstunFrames = computeHitstun(strength, defender.damage);
  defender.onGround = false;
  defender.currentMoveId = "none";
  applyAuraHitPenalty(defender, finalDamage >= 15);
  recordMoveUsed(attacker, moveId);

  const elementMode = state.config.ruleset?.elementMode ?? "on";
  if (elementGameplayEnabled(elementMode) && moveData) {
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
    launchAngleDeg: angleDeg,
    knockbackX: vx,
    knockbackY: vy,
    hitlagFrames: hitlag,
    hitstunFrames: defender.hitstunFrames,
    hitStrength: strength,
    element: attacker.elementEffect,
    cameraImpulseKind: cameraImpulseForStrength(strength),
  });
}

export function resolveCombatHits(
  state: GameState,
  inputs?: InputFrame[],
): HitEvent[] {
  const events: HitEvent[] = [];
  const inputByPlayer = new Map<number, InputFrame>();
  if (inputs) {
    for (const input of inputs) inputByPlayer.set(input.playerId, input);
  }

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

      const moveId = attacker.currentMoveId || "neutral_attack";
      if (!canHitVictim(attacker, defender.id, moveId, state.frame)) continue;

      const evt = resolveHitFromContact(
        state,
        attacker,
        defender,
        hit.damage,
        hit.knockbackX,
        hit.knockbackY,
        moveId,
        inputByPlayer.get(defender.id),
      );
      if (evt) {
        recordHitVictim(attacker, defender.id, state.frame, moveId);
        events.push(evt);
      }
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
      resetPlayerAfterRespawn(player, spawn, state.config.ruleset);
      const layout = getStageLayout(stageDef.layoutId ?? stageDef.id);
      player.currentPlatformId = layout.mainPlatformId;
    }
  }
  return anyKo;
}
