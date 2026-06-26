import type { ReplayRecord } from "@anime-aggressors/game-core";
import { verifyReplayRecord } from "@anime-aggressors/game-core";
import { saveReplay } from "../storage/replayStorage.ts";

export function parseReplayJson(json: string): ReplayRecord {
  return JSON.parse(json) as ReplayRecord;
}

export async function importReplayFromJson(json: string): Promise<ReplayRecord> {
  const record = parseReplayJson(json);
  const verification = verifyReplayRecord(record);
  if (!verification.valid) {
    throw new Error(`Replay hash mismatch: expected ${record.finalStateHash}, got ${verification.reproducedHash}`);
  }
  return saveReplay(record);
}

export async function importReplayFromFile(file: File): Promise<ReplayRecord> {
  const text = await file.text();
  return importReplayFromJson(text);
}
