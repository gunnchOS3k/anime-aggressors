import type { TeamId } from "./types.js";

export type StatEvent =
  | { type: "matchStarted"; frame: number; mode: string }
  | { type: "matchEnded"; frame: number; winnerPlayerId?: number; winningTeam?: TeamId }
  | { type: "ko"; frame: number; attackerPlayerId: number; victimPlayerId: number }
  | { type: "fall"; frame: number; victimPlayerId: number }
  | { type: "damage"; frame: number; attackerPlayerId: number; victimPlayerId: number; amount: number }
  | { type: "attackUsed"; frame: number; playerId: number; moveId: string }
  | { type: "attackLanded"; frame: number; playerId: number; moveId: string }
  | { type: "attackWhiffed"; frame: number; playerId: number; moveId: string }
  | { type: "specialUsed"; frame: number; playerId: number; moveId: string }
  | { type: "shieldUsed"; frame: number; playerId: number }
  | { type: "dodgeUsed"; frame: number; playerId: number }
  | { type: "grabUsed"; frame: number; playerId: number }
  | { type: "flaglineRoomWon"; frame: number; teamId: TeamId; roomIndex: number }
  | { type: "flaglineCoreCaptured"; frame: number; teamId: TeamId; playerIds: number[] }
  | {
      type: "derbyLaunched";
      frame: number;
      playerId: number;
      distance: number;
      score: number;
      launchSpeed: number;
    };

export function collectStatEventsForFrame(
  prevEvents: StatEvent[],
  nextEvents: StatEvent[],
): StatEvent[] {
  return [...prevEvents, ...nextEvents];
}
