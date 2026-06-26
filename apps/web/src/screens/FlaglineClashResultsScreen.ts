import type { TeamId, FlaglineClashState } from "@anime-aggressors/game-core";
import type { MatchEndResult } from "../career/careerService.ts";
import { navigateTo } from "../router.ts";

export function mountFlaglineClashResultsScreen(
  root: HTMLElement,
  state: FlaglineClashState,
  onRematch: () => void,
  onHome: () => void,
  careerResult?: MatchEndResult | null,
): void {
  const winner = state.flagline.winningTeam;
  const teamLabel = winner === "solar" ? "Solar Team" : "Lunar Team";
  root.innerHTML = `
    <div class="screen flagline-results">
      <h2>Flagline Clash Results</h2>
      <p class="winner-line">${winner ? `${teamLabel} wins!` : "Draw"}</p>
      <p>Rooms won — Solar: ${state.flagline.roomsWon.solar} · Lunar: ${state.flagline.roomsWon.lunar}</p>
      ${careerResult?.replay ? `<p>Replay saved · <button type="button" id="fl-watch-replay" class="btn-secondary">Watch Replay</button></p>` : ""}
      <div class="create-actions">
        <button type="button" id="fl-career" class="btn-secondary">View Career</button>
        <button type="button" id="fl-rematch" class="btn-primary">Rematch</button>
        <button type="button" id="fl-home" class="btn-secondary">Home</button>
      </div>
    </div>
  `;
  root.querySelector("#fl-rematch")?.addEventListener("click", onRematch);
  root.querySelector("#fl-home")?.addEventListener("click", onHome);
  root.querySelector("#fl-career")?.addEventListener("click", () => navigateTo("career"));
  root.querySelector("#fl-watch-replay")?.addEventListener("click", () => {
    if (careerResult?.replay) navigateTo("replay", { id: careerResult.replay.id });
  });
}

export function teamDisplayName(team: TeamId): string {
  return team === "solar" ? "Solar Team" : "Lunar Team";
}
