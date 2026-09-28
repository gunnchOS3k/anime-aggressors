import type { TeamAssignment } from "./types.js";

export type PartyTeamMode = "FFA" | "2v2" | "3v3" | "4v4" | "2v2v2v2";

/** Map seat index → team assignment for Party Mode team selectors. */
export function teamForSeat(mode: PartyTeamMode, seatIndex: number): TeamAssignment {
  if (mode === "FFA") return { mode: "FFA" };
  if (mode === "2v2") return { mode: "2v2", teamId: (seatIndex % 2 === 0 ? 0 : 1) as 0 | 1 };
  if (mode === "3v3") return { mode: "3v3", teamId: (seatIndex < 3 ? 0 : 1) as 0 | 1 };
  if (mode === "4v4") return { mode: "4v4", teamId: (seatIndex < 4 ? 0 : 1) as 0 | 1 };
  // 2v2v2v2 — seats 0-1, 2-3, 4-5, 6-7
  return { mode: "2v2v2v2", teamId: Math.floor(seatIndex / 2) as 0 | 1 | 2 | 3 };
}

export function requiredSeatsForTeamMode(mode: PartyTeamMode): number {
  switch (mode) {
    case "FFA":
      return 2;
    case "2v2":
      return 4;
    case "3v3":
      return 6;
    case "4v4":
    case "2v2v2v2":
      return 8;
  }
}

export const PARTY_TEAM_MODES: PartyTeamMode[] = ["FFA", "2v2", "3v3", "4v4", "2v2v2v2"];
