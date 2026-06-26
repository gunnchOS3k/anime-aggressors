import { evaluateMilestones } from "@anime-aggressors/game-core";
import { getCareerSummary } from "../storage/careerStorage.ts";
import { careerNav, formatPlaytime, mountScreenShell } from "./careerScreenShared.ts";
import { APP_ROUTES } from "../routes.ts";

export async function mountCareerScreen(root: HTMLElement): Promise<void> {
  const { career, fighterStats, recentMatches } = await getCareerSummary();
  const winRate =
    career.totalWins + career.totalLosses === 0
      ? 0
      : Math.round((career.totalWins / (career.totalWins + career.totalLosses)) * 1000) / 10;

  const bestDerby = fighterStats.reduce(
    (best, f) => Math.max(best, f.derbyBestScore),
    0,
  );
  const flaglineRooms = fighterStats.reduce((s, f) => s + f.flaglineRoomsWon, 0);
  const favoriteFighter = fighterStats.find((f) => f.fighterId === career.favoriteFighterId);

  const recentHtml =
    recentMatches.length === 0
      ? "<p>No matches recorded yet.</p>"
      : `<ul class="career-list">${recentMatches
          .map(
            (m) =>
              `<li><a href="${APP_ROUTES.careerHistory}">${new Date(m.endedAt).toLocaleString()} — ${m.mode} — ${m.stageName}</a></li>`,
          )
          .join("")}</ul>`;

  mountScreenShell(
    root,
    { title: "Career", subtitle: career.displayName },
    `
      ${careerNav()}
      <section class="career-grid">
        <div class="stat-card"><span>Playtime</span><strong>${formatPlaytime(career.totalPlaytimeFrames)}</strong></div>
        <div class="stat-card"><span>Matches</span><strong>${career.totalMatches}</strong></div>
        <div class="stat-card"><span>Wins / Losses</span><strong>${career.totalWins} / ${career.totalLosses}</strong></div>
        <div class="stat-card"><span>Win Rate</span><strong>${winRate}%</strong></div>
        <div class="stat-card"><span>Total KOs</span><strong>${career.totalKOs}</strong></div>
        <div class="stat-card"><span>Total Falls</span><strong>${career.totalFalls}</strong></div>
        <div class="stat-card"><span>Damage Dealt</span><strong>${career.totalDamageDealt}</strong></div>
        <div class="stat-card"><span>Damage Taken</span><strong>${career.totalDamageTaken}</strong></div>
        <div class="stat-card"><span>Favorite Fighter</span><strong>${favoriteFighter?.fighterName ?? "—"}</strong></div>
        <div class="stat-card"><span>Favorite Mode</span><strong>${career.favoriteMode ?? "—"}</strong></div>
        <div class="stat-card"><span>Best Derby Score</span><strong>${bestDerby}</strong></div>
        <div class="stat-card"><span>Flagline Rooms Won</span><strong>${flaglineRooms}</strong></div>
      </section>
      <section>
        <h2>Recent Matches</h2>
        ${recentHtml}
      </section>
      <p class="milestone-hint">${evaluateMilestones(career, fighterStats).length} milestones earned — <a href="${APP_ROUTES.careerMilestones}">View all</a></p>
    `,
  );
}
