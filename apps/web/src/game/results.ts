import { getCharacter, type GameState } from "@anime-aggressors/game-core";

export type ResultsAction = "rematch" | "menu";

export function showResults(
  root: HTMLElement,
  state: GameState,
  onAction: (action: ResultsAction) => void,
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
      <div class="vs-results-actions">
        <button id="vs-rematch" type="button">Rematch</button>
        <button id="vs-menu" type="button">Character Select</button>
      </div>
    </div>
  `;

  root.querySelector("#vs-rematch")?.addEventListener("click", () => onAction("rematch"));
  root.querySelector("#vs-menu")?.addEventListener("click", () => onAction("menu"));
}
