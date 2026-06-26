import type { ReplayRecord } from "@anime-aggressors/game-core";
import { idbDelete, idbGet, idbList, idbPut } from "./careerDb.ts";

export async function saveReplay(record: ReplayRecord): Promise<ReplayRecord> {
  await idbPut("replays", record);
  return record;
}

export async function getReplay(id: string): Promise<ReplayRecord | null> {
  return idbGet<ReplayRecord>("replays", id);
}

export async function listReplays(): Promise<ReplayRecord[]> {
  const all = await idbList<ReplayRecord>("replays");
  return all.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

export async function deleteReplay(id: string): Promise<void> {
  await idbDelete("replays", id);
}

export async function renameReplay(id: string, title: string): Promise<ReplayRecord | null> {
  const existing = await getReplay(id);
  if (!existing) return null;
  const updated = { ...existing, title };
  await idbPut("replays", updated);
  return updated;
}
