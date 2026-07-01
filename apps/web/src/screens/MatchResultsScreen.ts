import type { GameState, MatchRecord, ReplayRecord } from "@anime-aggressors/game-core";
import { navigateTo } from "../router.js";
import { renderWinnerHero, renderResultsScoreboard, renderResultsActions } from "../ui/results/WinnerHero.ts";
import { ARENA_CLASSES } from "../ui/theme/arenaClasses.ts";

export type ResultsAction = "rematch" | "menu" | "career" | "replay" | "save-replay";

export type MatchResultsContext = {
  match?: MatchRecord;
  replay?: ReplayRecord | null;
};

export function mountMatchResultsScreen(
  root: HTMLElement,
  state: GameState,
  onAction: (action: ResultsAction) => void,
  context: MatchResultsContext = {},
): void {
  root.innerHTML = `
    <div class="${ARENA_CLASSES.shell} match-results-screen">
      ${renderWinnerHero(state)}
      ${renderResultsScoreboard(state, context.match)}
      ${context.match ? `<p class="results-meta">Match time: ${Math.floor(context.match.durationFrames / 60)}s</p>` : ""}
      ${renderResultsActions(!!context.replay)}
    </div>
  `;

  root.querySelector("#vs-watch-replay")?.addEventListener("click", () => {
    if (context.replay) navigateTo("replay", { id: context.replay.id });
    onAction("replay");
  });
  root.querySelector("#vs-rematch")?.addEventListener("click", () => onAction("rematch"));
  root.querySelector("#vs-change-fighters")?.addEventListener("click", () => {
    navigateTo("match-setup-fighters");
  });
  root.querySelector("#vs-change-stage")?.addEventListener("click", () => {
    navigateTo("stage-select");
  });
  root.querySelector("#vs-menu")?.addEventListener("click", () => onAction("menu"));
}

export function showResults(
  root: HTMLElement,
  state: GameState,
  onAction: (action: ResultsAction) => void,
  context: MatchResultsContext = {},
): void {
  mountMatchResultsScreen(root, state, onAction, context);
}

export type ResultsContext = MatchResultsContext;
