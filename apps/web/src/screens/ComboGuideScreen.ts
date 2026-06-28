import {
  DEFAULT_FIGHTERS,
  getComboRoutesForFighter,
  getFighterMoveset,
} from "@anime-aggressors/game-core";
import { renderComboRouteCard, groupRoutesByDifficulty } from "../ui/ComboRouteCard.js";
import { navigateToHash, APP_ROUTES } from "../routes.js";

function fighterFromQuery(): string {
  const hash = window.location.hash;
  const qs = hash.split("?")[1] ?? "";
  const param = new URLSearchParams(qs).get("fighter");
  if (param && DEFAULT_FIGHTERS.some((f) => f.id === param)) return param;
  return DEFAULT_FIGHTERS[0]!.id;
}

function renderDifficultySection(
  label: string,
  routes: ReturnType<typeof getComboRoutesForFighter>,
  moveNames: Record<string, string>,
): string {
  if (!routes.length) return "";
  return `
    <section class="combo-difficulty-section">
      <h3>${label}</h3>
      <div class="combo-route-grid">
        ${routes.map((r) => renderComboRouteCard({ route: r, moveNames })).join("")}
      </div>
    </section>`;
}

export function mountComboGuideScreen(root: HTMLElement): void {
  let fighterId = fighterFromQuery();

  const render = () => {
    const routes = getComboRoutesForFighter(fighterId);
    const grouped = groupRoutesByDifficulty(routes);
    const names = Object.fromEntries(getFighterMoveset(fighterId).map((m) => [m.slot, m.displayName]));
    const fighter = DEFAULT_FIGHTERS.find((f) => f.id === fighterId)!;

    root.innerHTML = `
      <div class="screen combo-guide-screen">
        <div class="screen-toolbar">
          <button type="button" id="cg-back" class="btn-secondary">← Home</button>
          <h2>Combo Guide</h2>
        </div>
        <p class="hint">Simple routes using universal inputs — timing and spacing, not memorized strings.</p>
        <div class="fighter-tabs" role="tablist">
          ${DEFAULT_FIGHTERS.map(
            (f) => `
            <button
              type="button"
              class="fighter-tab ${f.id === fighterId ? "active" : ""}"
              data-fighter="${f.id}"
              role="tab"
            >${f.name}</button>`,
          ).join("")}
        </div>
        <div class="combo-guide-header">
          <h3>${fighter.name} — Combo Routes</h3>
        </div>
        ${renderDifficultySection("Beginner Routes", grouped.beginner, names)}
        ${renderDifficultySection("Intermediate Routes", grouped.intermediate, names)}
        ${renderDifficultySection("Advanced Routes", grouped.advanced, names)}
        <div class="create-actions">
          <button type="button" id="cg-moves" class="btn-secondary">Move List</button>
        </div>
      </div>
    `;

    root.querySelector("#cg-back")?.addEventListener("click", () => navigateToHash(APP_ROUTES.home));
    root.querySelector("#cg-moves")?.addEventListener("click", () => {
      navigateToHash(`${APP_ROUTES.moves}?fighter=${fighterId}`);
    });
    root.querySelectorAll(".fighter-tab").forEach((btn) => {
      btn.addEventListener("click", () => {
        fighterId = (btn as HTMLButtonElement).dataset.fighter!;
        const hash = `${APP_ROUTES.combos}?fighter=${fighterId}`;
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
