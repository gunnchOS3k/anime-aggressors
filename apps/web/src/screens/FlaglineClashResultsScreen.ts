import type { TeamId, FlaglineClashState } from "@anime-aggressors/game-core";

export function mountFlaglineClashResultsScreen(
  root: HTMLElement,
  state: FlaglineClashState,
  onRematch: () => void,
  onHome: () => void,
): void {
  const winner = state.flagline.winningTeam;
  const teamLabel = winner === "solar" ? "Solar Team" : "Lunar Team";
  root.innerHTML = `
    <div class="screen flagline-results">
      <h2>Flagline Clash Results</h2>
      <p class="winner-line">${winner ? `${teamLabel} wins!` : "Draw"}</p>
      <p>Rooms won — Solar: ${state.flagline.roomsWon.solar} · Lunar: ${state.flagline.roomsWon.lunar}</p>
      <div class="create-actions">
        <button type="button" id="fl-rematch" class="btn-primary">Rematch</button>
        <button type="button" id="fl-home" class="btn-secondary">Home</button>
      </div>
    </div>
  `;
  root.querySelector("#fl-rematch")?.addEventListener("click", onRematch);
  root.querySelector("#fl-home")?.addEventListener("click", onHome);
}

export function teamDisplayName(team: TeamId): string {
  return team === "solar" ? "Solar Team" : "Lunar Team";
}
