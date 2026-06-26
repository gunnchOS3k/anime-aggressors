import { getCharacter, type GameState, type MatchRecord, type ReplayRecord } from "@anime-aggressors/game-core";
import { navigateTo } from "../router.js";

export type ResultsAction = "rematch" | "menu" | "career" | "replay" | "save-replay";

export type ResultsContext = {
  match?: MatchRecord;
  replay?: ReplayRecord | null;
};

export function showResults(
  root: HTMLElement,
  state: GameState,
  onAction: (action: ResultsAction) => void,
  context: ResultsContext = {},
): void {
  const winner =
    state.winnerId !== null
      ? getCharacter(state.players[state.winnerId].characterId).name
      : "Draw";

  root.innerHTML = `
    <div class="vs-results">
      <h2>Match Results</h2>
      <p class="vs-winner">Winner: ${winner}</p>
      <ul>
        ${state.players
          .map((p) => {
            const c = getCharacter(p.characterId);
            return `<li>${c.name} — ${p.damage}% — stocks ${p.stocks}</li>`;
          })
          .join("")}
      </ul>
      ${context.match ? `<p class="results-meta">Recorded to Match History · ${context.match.durationFrames} frames</p>` : ""}
      ${context.replay ? `<p class="results-meta">Replay saved · hash <code>${context.replay.finalStateHash}</code></p>` : ""}
      <div class="vs-results-actions">
        ${context.replay ? `<button id="vs-watch-replay" type="button">Watch Replay</button>` : ""}
        <button id="vs-career" type="button">View Career</button>
        <button id="vs-rematch" type="button">Rematch</button>
        <button id="vs-menu" type="button">Main Menu</button>
      </div>
    </div>
  `;

  root.querySelector("#vs-watch-replay")?.addEventListener("click", () => {
    if (context.replay) navigateTo("replay", { id: context.replay.id });
    onAction("replay");
  });
  root.querySelector("#vs-career")?.addEventListener("click", () => {
    navigateTo("career");
    onAction("career");
  });
  root.querySelector("#vs-rematch")?.addEventListener("click", () => onAction("rematch"));
  root.querySelector("#vs-menu")?.addEventListener("click", () => onAction("menu"));
}
