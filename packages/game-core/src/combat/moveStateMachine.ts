import type { PlayerState } from "../types.js";
import { getCombatMoveData } from "../moves/combatMoveData.js";
import { combatMoveToFrameData } from "../moves/combatMoveData.js";
import { getFrameDataForMoveId } from "../moves/moveDefinitions.js";
import { getMoveData, type MoveId } from "../moves.js";
import { fightingTimingFromFrameData, getMovePhase, type FightingMoveTiming, type MovePhase } from "./movePhases.js";

export function getFightingMoveTiming(player: PlayerState): FightingMoveTiming | null {
  const catalog = getCombatMoveData(player.currentMoveId);
  if (catalog) {
    return fightingTimingFromFrameData({
      startup: catalog.startup,
      active: catalog.active,
      recovery: catalog.recovery,
      hitstop: catalog.hitstop,
    });
  }
  const fighterData = getFrameDataForMoveId(player.currentMoveId);
  if (fighterData) {
    return fightingTimingFromFrameData({
      startup: fighterData.startup,
      active: fighterData.active,
      recovery: fighterData.recovery,
    });
  }
  const legacy = getMoveData(player.currentMoveId as MoveId);
  if (!legacy) return null;
  return fightingTimingFromFrameData({
    startup: legacy.startup,
    active: legacy.active,
    recovery: legacy.recovery,
  });
}

export function currentMovePhase(player: PlayerState): MovePhase {
  if (
    player.actionState !== "attacking" &&
    player.actionState !== "special" &&
    player.actionState !== "grabbing"
  ) {
    return "idle";
  }
  const timing = getFightingMoveTiming(player);
  if (!timing) return "idle";
  return getMovePhase(player.actionFrame, timing);
}

export function isMoveInActiveFrames(player: PlayerState): boolean {
  return currentMovePhase(player) === "active";
}
