import { DEFAULT_FIGHTERS, getFighterMoveset } from "@anime-aggressors/game-core";
import { renderMoveCard } from "../ui/MoveCard.js";
import { navigateToHash, APP_ROUTES } from "../routes.js";

function fighterFromQuery(): string {
  const hash = window.location.hash;
  const qs = hash.split("?")[1] ?? "";
  const param = new URLSearchParams(qs).get("fighter");
  if (param && DEFAULT_FIGHTERS.some((f) => f.id === param)) return param;
  return DEFAULT_FIGHTERS[0]!.id;
}

export function mountMoveListScreen(root: HTMLElement): void {
  let fighterId = fighterFromQuery();

  const render = () => {
    const moves = getFighterMoveset(fighterId);
    const names = Object.fromEntries(moves.map((m) => [m.slot, m.displayName]));
    const fighter = DEFAULT_FIGHTERS.find((f) => f.id === fighterId)!;

    root.innerHTML = `
      <div class="screen move-list-screen">
        <div class="screen-toolbar">
          <button type="button" id="ml-back" class="btn-secondary">← Home</button>
          <h2>Move List</h2>
        </div>
        <p class="hint">Universal inputs — no command strings. Pick a fighter to browse their kit.</p>
        <div class="fighter-tabs" role="tablist">
          ${DEFAULT_FIGHTERS.map(
            (f) => `
            <button
              type="button"
              class="fighter-tab ${f.id === fighterId ? "active" : ""}"
              data-fighter="${f.id}"
              role="tab"
              aria-selected="${f.id === fighterId}"
            >${f.name}</button>`,
          ).join("")}
        </div>
        <div class="move-list-header">
          <h3>${fighter.name}</h3>
          <p class="fighter-tagline">${fighter.shortTagline}</p>
        </div>
        <div class="move-list-universal">
          <article class="move-card move-card--aura">
            <h4>Aura Charge</h4>
            <p class="move-input">Hold Shield + Special</p>
            <p class="move-purpose">Build super power and enhance element effects</p>
            <p class="move-meta">Difficulty: beginner · Risk: vulnerable while charging</p>
          </article>
        </div>
        <div class="move-list-grid">
          ${moves
            .map((move) => {
              const followUps = (move.cancelInto ?? []).map((slot) => names[slot]);
              return renderMoveCard({ move, followUps });
            })
            .join("")}
        </div>
        <div class="create-actions">
          <button type="button" id="ml-combos" class="btn-secondary">Combo Guide</button>
        </div>
      </div>
    `;

    root.querySelector("#ml-back")?.addEventListener("click", () => navigateToHash(APP_ROUTES.home));
    root.querySelector("#ml-combos")?.addEventListener("click", () => {
      navigateToHash(`${APP_ROUTES.combos}?fighter=${fighterId}`);
    });
    root.querySelectorAll(".fighter-tab").forEach((btn) => {
      btn.addEventListener("click", () => {
        fighterId = (btn as HTMLButtonElement).dataset.fighter!;
        const hash = `${APP_ROUTES.moves}?fighter=${fighterId}`;
        if (window.location.hash !== hash) {
          window.location.hash = hash.slice(1);
        } else {
          render();
        }
      });
    });
  };

  render();
  window.addEventListener("hashchange", () => {
    fighterId = fighterFromQuery();
    render();
  });
}
