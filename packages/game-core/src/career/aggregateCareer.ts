import type { GameState } from "../types.js";
import { getStage } from "../stages.js";
import { ELEMENTS } from "../elements.js";
import type {
  CareerProfile,
  FighterCareerStats,
  MatchMode,
  MatchPlayerRecord,
  MatchRecord,
  TeamId,
} from "./types.js";
import type { StatEvent } from "./statEvents.js";
import { buildScoreboard } from "./scoreboard.js";
import {
  computeHitAccuracy,
  computeWinRate,
  createDefaultFighterStats,
} from "./stats.js";

type PlayerMeta = {
  playerId: number;
  playerName: string;
  fighterId: string;
  fighterName: string;
  teamId?: TeamId;
  isBot: boolean;
  size: FighterCareerStats["size"];
  color: FighterCareerStats["color"];
  elementName: string;
};

function teamFromId(teamId: number): TeamId | undefined {
  if (teamId === 0) return "solar";
  if (teamId === 1) return "lunar";
  return undefined;
}

function extractPlayerMeta(state: GameState): PlayerMeta[] {
  return state.players.map((p) => ({
    playerId: p.id,
    playerName: `P${p.id + 1}`,
    fighterId: p.characterId,
    fighterName: p.fighterName,
    teamId: teamFromId(p.teamId),
    isBot: false,
    size: p.fighterSize,
    color: p.fighterColor,
    elementName: ELEMENTS[p.fighterColor]?.name ?? "Unknown",
  }));
}

function emptyPlayerRecord(meta: PlayerMeta): MatchPlayerRecord {
  return {
    playerId: meta.playerId,
    playerName: meta.playerName,
    fighterId: meta.fighterId,
    fighterName: meta.fighterName,
    teamId: meta.teamId,
    isBot: meta.isBot,
    result: "incomplete",
    kos: 0,
    falls: 0,
    assists: 0,
    damageDealt: 0,
    damageTaken: 0,
    highestDamage: 0,
    attacksLanded: 0,
    attacksWhiffed: 0,
    specialsUsed: 0,
    shieldsUsed: 0,
    dodgesUsed: 0,
    grabsUsed: 0,
    objectiveScore: 0,
    captures: 0,
    roomsWon: 0,
  };
}

function modeFromEvents(events: StatEvent[], state: GameState): MatchMode {
  const started = events.find((e) => e.type === "matchStarted");
  if (started?.mode === "impactDummyDerby") return "impactDummyDerby";
  if (started?.mode === "flaglineClash") return "flaglineClash";
  if (started?.mode === "training") return "training";
  if (started?.mode === "customGame") return "customGame";
  if (state.config.ruleset?.matchType === "flaglineClash") return "flaglineClash";
  return "playMatch";
}

export function buildMatchRecordFromEvents(args: {
  initialState: GameState;
  finalState: GameState;
  events: StatEvent[];
  replayId?: string;
  saveGameId?: string;
  matchId?: string;
  startedAt?: string;
  endedAt?: string;
  playerMetas?: PlayerMeta[];
}): MatchRecord {
  const {
    initialState,
    finalState,
    events,
    replayId,
    saveGameId,
    matchId = `match-${Date.now()}`,
    startedAt = new Date().toISOString(),
    endedAt = new Date().toISOString(),
    playerMetas,
  } = args;

  const metas = playerMetas ?? extractPlayerMeta(finalState);
  const records = new Map<number, MatchPlayerRecord>();
  for (const meta of metas) {
    records.set(meta.playerId, emptyPlayerRecord(meta));
  }

  const damageByVictim = new Map<number, number>();
  for (const p of finalState.players) {
    damageByVictim.set(p.id, p.damage);
    const rec = records.get(p.id);
    if (rec) rec.highestDamage = p.damage;
  }

  for (const event of events) {
    switch (event.type) {
      case "damage": {
        const attacker = records.get(event.attackerPlayerId);
        const victim = records.get(event.victimPlayerId);
        if (attacker) attacker.damageDealt += event.amount;
        if (victim) victim.damageTaken += event.amount;
        break;
      }
      case "ko": {
        const attacker = records.get(event.attackerPlayerId);
        const victim = records.get(event.victimPlayerId);
        if (attacker) attacker.kos += 1;
        if (victim) victim.falls += 1;
        break;
      }
      case "fall": {
        const victim = records.get(event.victimPlayerId);
        if (victim) victim.falls += 1;
        break;
      }
      case "attackLanded": {
        const p = records.get(event.playerId);
        if (p) p.attacksLanded += 1;
        break;
      }
      case "attackWhiffed": {
        const p = records.get(event.playerId);
        if (p) p.attacksWhiffed += 1;
        break;
      }
      case "specialUsed": {
        const p = records.get(event.playerId);
        if (p) p.specialsUsed += 1;
        break;
      }
      case "shieldUsed": {
        const p = records.get(event.playerId);
        if (p) p.shieldsUsed += 1;
        break;
      }
      case "dodgeUsed": {
        const p = records.get(event.playerId);
        if (p) p.dodgesUsed += 1;
        break;
      }
      case "grabUsed": {
        const p = records.get(event.playerId);
        if (p) p.grabsUsed += 1;
        break;
      }
      case "flaglineRoomWon": {
        for (const rec of records.values()) {
          if (rec.teamId === event.teamId) rec.roomsWon += 1;
        }
        break;
      }
      case "flaglineCoreCaptured": {
        for (const pid of event.playerIds) {
          const p = records.get(pid);
          if (p) p.captures += 1;
        }
        break;
      }
      case "derbyLaunched": {
        const p = records.get(event.playerId);
        if (p) {
          p.derbyDistance = event.distance;
          p.derbyScore = event.score;
          p.objectiveScore = event.score;
        }
        break;
      }
      default:
        break;
    }
  }

  const ended = events.find((e) => e.type === "matchEnded");
  const winnerPlayerId = ended?.winnerPlayerId ?? finalState.winnerId ?? undefined;
  const winningTeam = ended?.winningTeam;
  const mode = modeFromEvents(events, finalState);
  const isTraining = mode === "training";

  for (const rec of records.values()) {
    if (isTraining) {
      rec.result = "training";
    } else if (winnerPlayerId !== undefined && winnerPlayerId !== null) {
      rec.result = rec.playerId === winnerPlayerId ? "win" : "loss";
    } else if (winningTeam && rec.teamId) {
      rec.result = rec.teamId === winningTeam ? "win" : "loss";
    } else {
      rec.result = "draw";
    }
    if (rec.damageDealt === 0 && rec.damageTaken === 0) {
      for (const p of finalState.players) {
        if (p.id === rec.playerId) {
          rec.highestDamage = p.damage;
        }
      }
    }
  }

  const stage = getStage(finalState.config.stageId);
  const players = [...records.values()].sort((a, b) => a.playerId - b.playerId);

  return {
    id: matchId,
    mode,
    rulesetId: finalState.config.ruleset?.id,
    rulesetName: finalState.config.ruleset?.name,
    startedAt,
    endedAt,
    durationFrames: finalState.frame - initialState.frame,
    winnerPlayerId: winnerPlayerId ?? undefined,
    winningTeam,
    stageId: finalState.config.stageId,
    stageName: stage.name,
    players,
    scoreboard: buildScoreboard(players),
    replayId,
    saveGameId,
    tags: [],
  };
}

export function applyMatchRecordToCareer(
  career: CareerProfile,
  fighterStats: FighterCareerStats[],
  match: MatchRecord,
  localPlayerId = 0,
): { career: CareerProfile; fighterStats: FighterCareerStats[] } {
  const now = new Date().toISOString();
  const statsMap = new Map(fighterStats.map((f) => [f.fighterId, { ...f }]));

  const localPlayer = match.players.find((p) => p.playerId === localPlayerId && !p.isBot);
  const localResult = localPlayer?.result;

  let totalKOs = career.totalKOs;
  let totalFalls = career.totalFalls;
  let totalDamageDealt = career.totalDamageDealt;
  let totalDamageTaken = career.totalDamageTaken;

  for (const p of match.players) {
    if (p.isBot) continue;
    let fs = statsMap.get(p.fighterId);
    if (!fs) {
      const meta = match.players.find((mp) => mp.fighterId === p.fighterId);
      fs = createDefaultFighterStats({
        fighterId: p.fighterId,
        fighterName: p.fighterName,
        size: "medium",
        color: "red",
        elementName: "Fire",
      });
      statsMap.set(p.fighterId, fs);
    }

    if (p.playerId === localPlayerId) {
      totalKOs += p.kos;
      totalFalls += p.falls;
      totalDamageDealt += p.damageDealt;
      totalDamageTaken += p.damageTaken;
    }

    fs.matchesPlayed += 1;
    fs.playtimeFrames += match.durationFrames;
    fs.kos += p.kos;
    fs.falls += p.falls;
    fs.assists += p.assists;
    fs.damageDealt += p.damageDealt;
    fs.damageTaken += p.damageTaken;
    fs.highestDamageInMatch = Math.max(fs.highestDamageInMatch, p.highestDamage);
    fs.attacksLanded += p.attacksLanded;
    fs.attacksWhiffed += p.attacksWhiffed;
    fs.specialsUsed += p.specialsUsed;
    fs.shieldsUsed += p.shieldsUsed;
    fs.dodgesUsed += p.dodgesUsed;
    fs.grabsUsed += p.grabsUsed;
    fs.flaglineRoomsWon += p.roomsWon;
    fs.flaglineCoresCaptured += p.captures;
    fs.hitAccuracy = computeHitAccuracy(fs.attacksLanded, fs.attacksWhiffed);
    fs.lastPlayedAt = now;

    if (p.derbyDistance !== undefined) {
      if (p.derbyDistance > fs.derbyBestDistance) fs.derbyBestDistance = p.derbyDistance;
      if ((p.derbyScore ?? 0) > fs.derbyBestScore) fs.derbyBestScore = p.derbyScore ?? 0;
    }

    if (p.result === "win") {
      fs.wins += 1;
    } else if (p.result === "loss") {
      fs.losses += 1;
    }
    fs.winRate = computeWinRate(fs.wins, fs.losses);
  }

  const modeCounts = new Map<string, number>();
  if (career.favoriteMode) modeCounts.set(career.favoriteMode, 1);
  modeCounts.set(match.mode, (modeCounts.get(match.mode) ?? 0) + 1);

  let favoriteMode = career.favoriteMode;
  let maxMode = 0;
  for (const [mode, count] of modeCounts) {
    if (count > maxMode) {
      maxMode = count;
      favoriteMode = mode;
    }
  }

  const fighterPlayCounts = new Map<string, number>();
  for (const fs of statsMap.values()) {
    fighterPlayCounts.set(fs.fighterId, fs.matchesPlayed);
  }
  let favoriteFighterId = career.favoriteFighterId;
  let maxFighter = 0;
  for (const [id, count] of fighterPlayCounts) {
    if (count > maxFighter) {
      maxFighter = count;
      favoriteFighterId = id;
    }
  }

  const updatedCareer: CareerProfile = {
    ...career,
    updatedAt: now,
    totalPlaytimeFrames: career.totalPlaytimeFrames + match.durationFrames,
    totalMatches: match.mode === "training" ? career.totalMatches : career.totalMatches + 1,
    totalWins:
      localResult === "win" && match.mode !== "training"
        ? career.totalWins + 1
        : career.totalWins,
    totalLosses:
      localResult === "loss" && match.mode !== "training"
        ? career.totalLosses + 1
        : career.totalLosses,
    totalKOs,
    totalFalls,
    totalDamageDealt,
    totalDamageTaken,
    favoriteFighterId,
    favoriteMode,
  };

  return {
    career: updatedCareer,
    fighterStats: [...statsMap.values()].sort((a, b) =>
      a.fighterName.localeCompare(b.fighterName),
    ),
  };
}

export type { PlayerMeta };
