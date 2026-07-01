import type { PlayerState } from "../types.js";
import { getCombatMoveData } from "../moves/combatMoveData.js";
import { combatMoveToFrameData } from "../moves/combatMoveData.js";
import { isMoveComplete } from "../moves.js";
import { isMovementLocked } from "../movement/landingLag.js";
import { isInShieldStun } from "./shieldSystem.js";

export function isInCombatRecovery(player: PlayerState): boolean {
  if (player.actionState === "attacking" || player.actionState === "special") {
    const move = getCombatMoveData(player.currentMoveId);
    if (!move) return false;
    const frameData = combatMoveToFrameData(move);
    const activeEnd = move.startup + move.active;
    return player.actionFrame > activeEnd && !isMoveComplete(frameData, player.actionFrame);
  }
  if (player.actionState === "grabbing") {
    const grab = getCombatMoveData("grab");
    if (!grab) return false;
    return player.actionFrame > grab.startup + grab.active;
  }
  return false;
}

export function canStartCombatAction(player: PlayerState): boolean {
  if (player.actionState === "defeated") return false;
  if (player.actionState === "hitstun") return false;
  if (player.actionState === "grabbed") return false;
  if (isMovementLocked(player)) return false;
  if (isInShieldStun(player)) return false;
  if (player.actionState === "auraCharging") return false;
  if (player.actionState === "dodging" || player.actionState === "rolling" || player.actionState === "airDodging") {
    return false;
  }
  if (player.actionState === "throwing") return false;

  if (player.actionState === "shielding") return false;

  if (player.actionState === "grabbing" && player.grabTargetId >= 0) {
    return true;
  }

  if (player.actionState === "attacking" || player.actionState === "special") {
    const move = getCombatMoveData(player.currentMoveId);
    if (!move) return true;
    const frameData = combatMoveToFrameData(move);
    return isMoveComplete(frameData, player.actionFrame);
  }

  if (player.actionState === "grabbing") {
    const grab = getCombatMoveData("grab");
    if (!grab) return true;
    return isMoveComplete(combatMoveToFrameData(grab), player.actionFrame);
  }

  return true;
}

export function resetCombatFields(player: PlayerState): void {
  player.hitstunFrames = 0;
  player.shieldStunFrames = 0;
  player.shieldReleaseFrames = 0;
  player.grabTargetId = -1;
  player.grabbedByPlayerId = -1;
  player.grabFrames = 0;
  player.dodgeCooldownFrames = 0;
  player.hitVictimsThisMove = [];
  player.multiHitContacts = [];
  player.staleMoveQueue = [];
  player.currentMoveId = "none";
}
