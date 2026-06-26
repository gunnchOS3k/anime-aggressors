import type { FighterColor } from "../elements.js";
import type { FighterSize } from "../sizeClasses.js";
import type { InputFrame } from "../types.js";
import type { TeamId } from "../modes/flaglineTypes.js";

export type { TeamId };

export type CareerProfile = {
  id: string;
  displayName: string;
  createdAt: string;
  updatedAt: string;
  totalPlaytimeFrames: number;
  totalMatches: number;
  totalWins: number;
  totalLosses: number;
  totalKOs: number;
  totalFalls: number;
  totalDamageDealt: number;
  totalDamageTaken: number;
  favoriteFighterId?: string;
  favoriteMode?: string;
};

export type FighterCareerStats = {
  fighterId: string;
  fighterName: string;
  size: FighterSize;
  color: FighterColor;
  elementName: string;

  matchesPlayed: number;
  wins: number;
  losses: number;
  winRate: number;

  playtimeFrames: number;
  kos: number;
  falls: number;
  assists: number;

  damageDealt: number;
  damageTaken: number;
  highestDamageInMatch: number;
  bestKOStreak: number;

  attacksLanded: number;
  attacksWhiffed: number;
  hitAccuracy: number;

  specialsUsed: number;
  shieldsUsed: number;
  dodgesUsed: number;
  grabsUsed: number;

  flaglineRoomsWon: number;
  flaglineCoresCaptured: number;
  flaglineDefensiveStops: number;

  derbyBestDistance: number;
  derbyBestScore: number;
  derbyBestLaunchSpeed: number;

  lastPlayedAt?: string;
};

export type MatchMode =
  | "playMatch"
  | "training"
  | "impactDummyDerby"
  | "flaglineClash"
  | "customGame";

export type MatchPlayerRecord = {
  playerId: number;
  playerName: string;
  fighterId: string;
  fighterName: string;
  teamId?: TeamId;
  isBot: boolean;

  result: "win" | "loss" | "draw" | "training" | "incomplete";

  kos: number;
  falls: number;
  assists: number;
  damageDealt: number;
  damageTaken: number;
  highestDamage: number;

  attacksLanded: number;
  attacksWhiffed: number;
  specialsUsed: number;
  shieldsUsed: number;
  dodgesUsed: number;
  grabsUsed: number;

  objectiveScore: number;
  captures: number;
  roomsWon: number;

  derbyDistance?: number;
  derbyScore?: number;
};

export type ScoreboardRow = {
  rank: number;
  playerId: number;
  playerName: string;
  fighterName: string;
  teamId?: TeamId;
  score: number;
  kos: number;
  falls: number;
  damage: number;
};

export type MatchRecord = {
  id: string;
  mode: MatchMode;
  rulesetId?: string;
  rulesetName?: string;

  startedAt: string;
  endedAt: string;
  durationFrames: number;

  winnerPlayerId?: number;
  winningTeam?: TeamId;

  stageId: string;
  stageName: string;

  players: MatchPlayerRecord[];
  scoreboard: ScoreboardRow[];

  replayId?: string;
  saveGameId?: string;

  tags: string[];
};

export type ReplayInputFrame = {
  frame: number;
  inputs: InputFrame[];
};

export type ReplayRecord = {
  id: string;
  matchId: string;
  createdAt: string;
  gameVersion: string;
  mode: string;
  ruleset: unknown;
  initialStateSerialized: string;
  inputLog: ReplayInputFrame[];
  finalStateHash: string;
  durationFrames: number;
  playerNames: string[];
  fighterNames: string[];
  title: string;
  notes?: string;
};

export type SaveGameRecord = {
  id: string;
  createdAt: string;
  updatedAt: string;
  gameVersion: string;
  mode: string;
  title: string;
  stateSerialized: string;
  currentFrame: number;
  ruleset: unknown;
  playerNames: string[];
  fighterNames: string[];
  screenshotDataUrl?: string;
};
