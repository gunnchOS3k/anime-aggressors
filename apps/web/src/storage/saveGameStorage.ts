import type { SaveGameRecord } from "@anime-aggressors/game-core";
import { idbDelete, idbGet, idbList, idbPut } from "./careerDb.ts";

const AUTO_SAVE_KEY = "aa-autosave-latest";

export async function saveGame(record: SaveGameRecord): Promise<SaveGameRecord> {
  const updated = { ...record, updatedAt: new Date().toISOString() };
  await idbPut("savedGames", updated);
  return updated;
}

export async function autoSaveLatest(record: SaveGameRecord): Promise<void> {
  await saveGame(record);
  if (typeof localStorage !== "undefined") {
    localStorage.setItem(AUTO_SAVE_KEY, record.id);
  }
}

export async function getAutoSaveId(): Promise<string | null> {
  if (typeof localStorage === "undefined") return null;
  return localStorage.getItem(AUTO_SAVE_KEY);
}

export async function getSavedGame(id: string): Promise<SaveGameRecord | null> {
  return idbGet<SaveGameRecord>("savedGames", id);
}

export async function listSavedGames(): Promise<SaveGameRecord[]> {
  const all = await idbList<SaveGameRecord>("savedGames");
  return all.sort((a, b) => b.updatedAt.localeCompare(a.updatedAt));
}

export async function deleteSavedGame(id: string): Promise<void> {
  await idbDelete("savedGames", id);
  if (typeof localStorage !== "undefined" && localStorage.getItem(AUTO_SAVE_KEY) === id) {
    localStorage.removeItem(AUTO_SAVE_KEY);
  }
}

export async function renameSavedGame(id: string, title: string): Promise<SaveGameRecord | null> {
  const existing = await getSavedGame(id);
  if (!existing) return null;
  const updated = { ...existing, title, updatedAt: new Date().toISOString() };
  await idbPut("savedGames", updated);
  return updated;
}
