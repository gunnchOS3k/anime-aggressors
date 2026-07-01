import type { GameState, PlayerState } from "../types.js";
import { FP_SCALE } from "../constants.js";
import { boxesOverlap, getGrabHitbox, getHurtbox } from "../collision.js";
import { getCombatMoveData } from "../moves/combatMoveData.js";
import { isInActive } from "../frameData.js";
import { combatMoveToFrameData } from "../moves/combatMoveData.js";
import { computeKnockback } from "./knockback.js";
import { computeHitlag } from "./hitlag.js";
import { computeHitstun } from "./hitstun.js";
import { classifyHitStrength } from "./combatTuning.js";
import { scaledHitDamage, scaledKnockbackTaken } from "../fighterCreation.js";
import { getCharacterForPlayer } from "../characters.js";
import { applyStaleMultiplier, recordMoveUsed } from "./staleMoves.js";

export const GRAB_TIMEOUT_FRAMES = 90;

export function tryGrabConnect(state: GameState, attacker: PlayerState): boolean {
  if (attacker.actionState !== "grabbing") return false;
  const grabData = getCombatMoveData("grab");
  if (!grabData) return false;
  const frameData = combatMoveToFrameData(grabData);
  if (!isInActive(frameData, attacker.actionFrame)) return false;
  if (attacker.grabTargetId >= 0) return false;

  const grabBox = getGrabHitbox(attacker);
  if (!grabBox) return false;

  for (const defender of state.players) {
    if (defender.id === attacker.id) continue;
    if (defender.actionState === "defeated") continue;
    if (defender.invulnFrames > 0) continue;
    if (defender.actionState === "grabbed") continue;

    const hurt = getHurtbox(defender);
    if (!boxesOverlap(grabBox, hurt)) continue;

    attacker.grabTargetId = defender.id;
    defender.actionState = "grabbed";
    defender.grabbedByPlayerId = attacker.id;
    defender.vx = 0;
    defender.vy = 0;
    defender.currentMoveId = "none";
    attacker.actionFrame = grabData.startup + grabData.active;
    return true;
  }
  return false;
}

export function tickGrabState(attacker: PlayerState, defender: PlayerState | undefined): void {
  if (attacker.actionState !== "grabbing") return;
  if (attacker.grabTargetId < 0) return;
  if (!defender || defender.actionState !== "grabbed") {
    clearGrab(attacker, defender);
    return;
  }
  defender.x = attacker.x + attacker.facing * 20 * FP_SCALE;
  defender.y = attacker.y;
  attacker.grabFrames += 1;
  if (attacker.grabFrames >= GRAB_TIMEOUT_FRAMES) {
    clearGrab(attacker, defender);
  }
}

export function clearGrab(attacker: PlayerState | undefined, defender: PlayerState | undefined): void {
  if (attacker) {
    attacker.grabTargetId = -1;
    attacker.grabFrames = 0;
    if (attacker.actionState === "grabbing") {
      attacker.actionState = "idle";
      attacker.currentMoveId = "none";
    }
  }
  if (defender && defender.actionState === "grabbed") {
    defender.actionState = "idle";
    defender.grabbedByPlayerId = -1;
  }
}

export function executeThrow(
  state: GameState,
  attacker: PlayerState,
  defender: PlayerState,
  moveId: string,
): void {
  const move = getCombatMoveData(moveId);
  if (!move) return;

  const preDamage = defender.damage;
  const dmgRatio = state.config.ruleset?.damageRatio ?? 1;
  const launchRatio = state.config.ruleset?.launchRatio ?? 1;
  const staleMult = applyStaleMultiplier(attacker, moveId);
  const finalDamage = Math.max(1, Math.floor(scaledHitDamage(move.damage, attacker) * dmgRatio * staleMult));

  defender.damage += finalDamage;
  recordMoveUsed(attacker, moveId);

  const char = getCharacterForPlayer(defender);
  const strength = classifyHitStrength(finalDamage, moveId);
  const kb = computeKnockback({
    moveDamage: finalDamage,
    baseKnockback: move.baseKnockback * staleMult,
    knockbackGrowth: move.knockbackGrowth,
    victimDamagePercent: preDamage,
    victimWeight: char.weight,
    launchRatio,
    hitStrength: strength,
    angleDeg: move.angleDeg,
  });

  let vx = (kb.vx * attacker.facing) / FP_SCALE;
  let vy = kb.vy / FP_SCALE;
  vx = scaledKnockbackTaken(Math.floor(vx * FP_SCALE), defender) / FP_SCALE;
  vy = scaledKnockbackTaken(Math.floor(vy * FP_SCALE), defender) / FP_SCALE;

  defender.vx = vx;
  defender.vy = vy;
  defender.actionState = "hitstun";
  defender.hitstunFrames = computeHitstun(strength, defender.damage);
  defender.onGround = false;
  defender.grabbedByPlayerId = -1;

  attacker.grabTargetId = -1;
  attacker.grabFrames = 0;
  attacker.actionState = "idle";
  attacker.currentMoveId = "none";

  const hitlag = computeHitlag(strength);
  if (hitlag > state.hitstopFrames) state.hitstopFrames = hitlag;
}

export function isGrabWhiffRecovery(attacker: PlayerState): boolean {
  if (attacker.actionState !== "grabbing") return false;
  if (attacker.grabTargetId >= 0) return false;
  const grab = getCombatMoveData("grab");
  if (!grab) return false;
  const frameData = combatMoveToFrameData(grab);
  return attacker.actionFrame > grab.startup + grab.active;
}
