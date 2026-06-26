import type { CareerProfile, FighterCareerStats } from "./types.js";

export function createDefaultCareerProfile(displayName = "Player"): CareerProfile {
  const now = new Date().toISOString();
  return {
    id: `career-${Date.now()}`,
    displayName,
    createdAt: now,
    updatedAt: now,
    totalPlaytimeFrames: 0,
    totalMatches: 0,
    totalWins: 0,
    totalLosses: 0,
    totalKOs: 0,
    totalFalls: 0,
    totalDamageDealt: 0,
    totalDamageTaken: 0,
  };
}

export function createDefaultFighterStats(args: {
  fighterId: string;
  fighterName: string;
  size: FighterCareerStats["size"];
  color: FighterCareerStats["color"];
  elementName: string;
}): FighterCareerStats {
  return {
    fighterId: args.fighterId,
    fighterName: args.fighterName,
    size: args.size,
    color: args.color,
    elementName: args.elementName,
    matchesPlayed: 0,
    wins: 0,
    losses: 0,
    winRate: 0,
    playtimeFrames: 0,
    kos: 0,
    falls: 0,
    assists: 0,
    damageDealt: 0,
    damageTaken: 0,
    highestDamageInMatch: 0,
    bestKOStreak: 0,
    attacksLanded: 0,
    attacksWhiffed: 0,
    hitAccuracy: 0,
    specialsUsed: 0,
    shieldsUsed: 0,
    dodgesUsed: 0,
    grabsUsed: 0,
    flaglineRoomsWon: 0,
    flaglineCoresCaptured: 0,
    flaglineDefensiveStops: 0,
    derbyBestDistance: 0,
    derbyBestScore: 0,
    derbyBestLaunchSpeed: 0,
  };
}

export function computeWinRate(wins: number, losses: number): number {
  const total = wins + losses;
  return total === 0 ? 0 : Math.round((wins / total) * 1000) / 10;
}

export function computeHitAccuracy(landed: number, whiffed: number): number {
  const total = landed + whiffed;
  return total === 0 ? 0 : Math.round((landed / total) * 1000) / 10;
}
