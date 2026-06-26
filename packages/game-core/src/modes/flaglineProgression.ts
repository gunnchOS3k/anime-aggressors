import { TEAM_PUSH_DIRECTION, type FlaglineRoomIndex, type TeamId, type FlaglineProgressionResult } from "./flaglineTypes.js";

export function getNextRoomIndex(
  currentRoom: FlaglineRoomIndex,
  winner: TeamId,
): FlaglineProgressionResult {
  const delta = TEAM_PUSH_DIRECTION[winner];
  const next = (currentRoom + delta) as FlaglineRoomIndex;

  if (winner === "solar" && currentRoom === -2) return "solarWinsGame";
  if (winner === "lunar" && currentRoom === 2) return "lunarWinsGame";

  if (next < -2 || next > 2) {
    return winner === "solar" ? "solarWinsGame" : "lunarWinsGame";
  }

  return next;
}

export function roomIndexToStripPosition(index: FlaglineRoomIndex): number {
  return index + 2;
}
