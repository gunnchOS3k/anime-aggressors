import type { CareerProfile, FighterCareerStats, MatchRecord } from "@anime-aggressors/game-core";
import {
  createDefaultCareerProfile,
  applyMatchRecordToCareer,
} from "@anime-aggressors/game-core";
import { idbGet, idbList, idbPut, idbDelete } from "./careerDb.ts";

const CAREER_KEY = "aa-career-profile";
const FIGHTER_INDEX_KEY = "aa-fighter-stats-index";

export function getCareerProfile(): CareerProfile {
  if (typeof localStorage === "undefined") return createDefaultCareerProfile();
  try {
    const raw = localStorage.getItem(CAREER_KEY);
    if (!raw) {
      const profile = createDefaultCareerProfile();
      localStorage.setItem(CAREER_KEY, JSON.stringify(profile));
      return profile;
    }
    return JSON.parse(raw) as CareerProfile;
  } catch {
    return createDefaultCareerProfile();
  }
}

export function saveCareerProfile(profile: CareerProfile): CareerProfile {
  const updated = { ...profile, updatedAt: new Date().toISOString() };
  localStorage.setItem(CAREER_KEY, JSON.stringify(updated));
  return updated;
}

export function updateDisplayName(name: string): CareerProfile {
  const profile = getCareerProfile();
  return saveCareerProfile({ ...profile, displayName: name });
}

export async function listFighterStats(): Promise<FighterCareerStats[]> {
  if (typeof localStorage === "undefined") return [];
  try {
    const raw = localStorage.getItem(FIGHTER_INDEX_KEY);
    const ids = raw ? (JSON.parse(raw) as string[]) : [];
    const stats: FighterCareerStats[] = [];
    for (const id of ids) {
      const s = await idbGet<FighterCareerStats>("fighterStats", id);
      if (s) stats.push(s);
    }
    return stats.sort((a, b) => a.fighterName.localeCompare(b.fighterName));
  } catch {
    return [];
  }
}

async function saveFighterStatsList(stats: FighterCareerStats[]): Promise<void> {
  const ids = stats.map((s) => s.fighterId);
  localStorage.setItem(FIGHTER_INDEX_KEY, JSON.stringify(ids));
  for (const s of stats) {
    await idbPut("fighterStats", s);
  }
}

export async function saveMatchHistory(record: MatchRecord): Promise<MatchRecord> {
  await idbPut("matchHistory", record);
  return record;
}

export async function listMatchHistory(): Promise<MatchRecord[]> {
  const all = await idbList<MatchRecord>("matchHistory");
  return all.sort((a, b) => b.endedAt.localeCompare(a.endedAt));
}

export async function deleteMatchHistory(id: string): Promise<void> {
  await idbDelete("matchHistory", id);
}

export async function recordMatchToCareer(
  match: MatchRecord,
  localPlayerId = 0,
): Promise<{ career: CareerProfile; fighterStats: FighterCareerStats[] }> {
  const career = getCareerProfile();
  const fighterStats = await listFighterStats();
  const result = applyMatchRecordToCareer(career, fighterStats, match, localPlayerId);
  saveCareerProfile(result.career);
  await saveFighterStatsList(result.fighterStats);
  await saveMatchHistory(match);
  return result;
}

export async function getCareerSummary(): Promise<{
  career: CareerProfile;
  fighterStats: FighterCareerStats[];
  recentMatches: MatchRecord[];
}> {
  const career = getCareerProfile();
  const fighterStats = await listFighterStats();
  const recentMatches = (await listMatchHistory()).slice(0, 5);
  return { career, fighterStats, recentMatches };
}
