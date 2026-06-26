import type { ReplayRecord } from "@anime-aggressors/game-core";

export function exportReplayToJson(record: ReplayRecord): string {
  return JSON.stringify(record, null, 2);
}

export function downloadReplay(record: ReplayRecord): void {
  const blob = new Blob([exportReplayToJson(record)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `${record.title.replace(/\s+/g, "-").toLowerCase()}-${record.id}.json`;
  a.click();
  URL.revokeObjectURL(url);
}
