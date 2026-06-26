import type { MatchPlayerRecord, ScoreboardRow } from "./types.js";

export function buildScoreboard(players: MatchPlayerRecord[]): ScoreboardRow[] {
  const rows = players.map((p) => ({
    rank: 0,
    playerId: p.playerId,
    playerName: p.playerName,
    fighterName: p.fighterName,
    teamId: p.teamId,
    score: p.objectiveScore || p.derbyScore || (p.result === "win" ? 1 : 0),
    kos: p.kos,
    falls: p.falls,
    damage: p.damageDealt,
  }));

  rows.sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score;
    if (b.kos !== a.kos) return b.kos - a.kos;
    return b.damage - a.damage;
  });

  return rows.map((row, i) => ({ ...row, rank: i + 1 }));
}
