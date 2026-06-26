import type { PlayerState } from "../types.js";
import type { FlaglineConfig, FlaglineMetaState, FlaglineRoom, TeamId } from "./flaglineTypes.js";
import { SIM_HZ } from "../constants.js";

function isAlive(p: PlayerState): boolean {
  return p.actionState !== "defeated" && p.stocks > 0;
}

function inFlagCore(p: PlayerState, room: FlaglineRoom): boolean {
  const { x, y, width, height } = room.flagCore;
  const left = x - width / 2;
  const right = x + width / 2;
  const top = y - height / 2;
  const bottom = y + height / 2;
  return p.x >= left && p.x <= right && p.y >= top && p.y <= bottom;
}

export function countTeamsInCore(
  players: PlayerState[],
  teamSlots: { playerId: number; teamId: TeamId }[],
  room: FlaglineRoom,
): { solar: number; lunar: number } {
  let solar = 0;
  let lunar = 0;
  for (const slot of teamSlots) {
    const p = players[slot.playerId];
    if (!p || !isAlive(p) || !inFlagCore(p, room)) continue;
    if (slot.teamId === "solar") solar += 1;
    else lunar += 1;
  }
  return { solar, lunar };
}

export function updateFlagCoreCapture(
  flagline: FlaglineMetaState,
  players: PlayerState[],
  teamSlots: { playerId: number; teamId: TeamId }[],
  room: FlaglineRoom,
  config: FlaglineConfig,
  deltaFrames: number,
): FlaglineMetaState {
  const next = {
    ...flagline,
    capture: { ...flagline.capture },
  };
  const counts = countTeamsInCore(players, teamSlots, room);
  const rate = (config.captureRatePerSecond * deltaFrames) / SIM_HZ;
  const decay = (config.decayRatePerSecond * deltaFrames) / SIM_HZ;

  if (counts.solar > 0 && counts.lunar > 0) {
    next.capture.contested = true;
    next.capture.controllingTeam = null;
  } else if (counts.solar > 0) {
    next.capture.contested = false;
    next.capture.controllingTeam = "solar";
    next.capture.solar = Math.min(config.captureToWin, next.capture.solar + rate);
  } else if (counts.lunar > 0) {
    next.capture.contested = false;
    next.capture.controllingTeam = "lunar";
    next.capture.lunar = Math.min(config.captureToWin, next.capture.lunar + rate);
  } else {
    next.capture.contested = false;
    next.capture.controllingTeam = null;
    next.capture.solar = Math.max(0, next.capture.solar - decay);
    next.capture.lunar = Math.max(0, next.capture.lunar - decay);
  }

  return next;
}

export function checkCaptureWin(
  flagline: FlaglineMetaState,
  config: FlaglineConfig,
): TeamId | null {
  if (flagline.capture.solar >= config.captureToWin) return "solar";
  if (flagline.capture.lunar >= config.captureToWin) return "lunar";
  return null;
}

export function resetCaptureMeters(flagline: FlaglineMetaState): FlaglineMetaState {
  return {
    ...flagline,
    capture: {
      solar: 0,
      lunar: 0,
      contested: false,
      controllingTeam: null,
    },
    roomWinner: null,
    roomWinReason: null,
  };
}
