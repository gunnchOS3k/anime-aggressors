import type { GameState } from "@anime-aggressors/game-core";
import { getCharacter } from "@anime-aggressors/game-core";
import { renderFighterPortraitHtml } from "../../renderer-three/portraits/FighterPortraitFactory.ts";
import { victorySubtitleForFighter } from "../../renderer-three/fighters/victoryAnimations.ts";
import { ARENA_CLASSES } from "../theme/arenaClasses.ts";

export function renderWinnerHero(state: GameState): string {
  const winnerId = state.winnerId;
  const winner = winnerId !== null ? state.players[winnerId] : null;
  const name = winner ? (winner.fighterName || getCharacter(winner.characterId).name) : "Draw";
  const winnerFighterId = winner?.characterId.replace(/^created:/, "") ?? "";
  const subtitle =
    winnerId !== null ? victorySubtitleForFighter(winnerFighterId || winner!.fighterName) : "No victor";

  return `<div class="results-winner-hero">
    <p class="results-winner-label">WINNER</p>
    <h1 class="results-winner-name">${name.toUpperCase()}</h1>
    <p class="results-winner-subtitle">${subtitle}</p>
    ${winner ? renderFighterPortraitHtml(winner.characterId.replace(/^created:/, ""), 120) : ""}
    <canvas id="results-winner-canvas" class="results-winner-canvas" width="480" height="320" aria-hidden="true"></canvas>
  </div>`;
}

export function renderResultsScoreboard(state: GameState): string {
  const rows = state.players
    .map((p) => {
      const label = p.fighterName || getCharacter(p.characterId).name;
      const isWinner = state.winnerId === p.id;
      return `<tr class="${isWinner ? "results-row--winner" : ""}">
        <td>${label}</td>
        <td>${p.damage}%</td>
        <td>${p.stocks}</td>
        <td>${p.score}</td>
      </tr>`;
    })
    .join("");

  return `<table class="results-scoreboard">
    <thead><tr><th>Fighter</th><th>Damage</th><th>Stocks</th><th>Score</th></tr></thead>
    <tbody>${rows}</tbody>
  </table>`;
}

export function renderResultsActions(hasReplay: boolean): string {
  return `<div class="results-actions">
    ${hasReplay ? `<button type="button" id="vs-watch-replay" class="${ARENA_CLASSES.secondaryBtn}">Watch Replay</button>` : ""}
    <button type="button" id="vs-rematch" class="${ARENA_CLASSES.primaryCta}">Rematch</button>
    <button type="button" id="vs-change-fighters" class="${ARENA_CLASSES.secondaryBtn}">Change Fighters</button>
    <button type="button" id="vs-career" class="${ARENA_CLASSES.secondaryBtn}">Career</button>
    <button type="button" id="vs-menu" class="${ARENA_CLASSES.secondaryBtn}">Main Menu</button>
  </div>`;
}
