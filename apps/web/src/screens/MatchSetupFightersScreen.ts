import type { CreatedFighter } from "@anime-aggressors/game-core";
import {
  ELEMENTS,
  SIZE_STATS,
  getDefaultCreatedFighter,
} from "@anime-aggressors/game-core";
import { listCreatedFighters } from "../storage/createdFightersStorage.js";
import { APP_ROUTES, navigateToHash } from "../routes.js";
import { loadMatchSetup, saveMatchSetup } from "../match/matchSetupSession.js";

function fighterCard(f: CreatedFighter, selected: boolean, player: number): string {
  const stats = SIZE_STATS[f.size];
  return `
    <button type="button" class="fighter-pick ${selected ? "selected" : ""}" data-player="${player}" data-id="${f.id}"
      style="border-color:${ELEMENTS[f.color].hexColor}">
      <strong>${f.name}</strong><br/>
      <small>${stats.label} · ${ELEMENTS[f.color].name}</small><br/>
      <span class="element-badge" style="background:${ELEMENTS[f.color].hexColor}33;border:1px solid ${ELEMENTS[f.color].hexColor}">${ELEMENTS[f.color].name}</span>
      <span class="size-badge">${stats.label}</span><br/>
      <small class="mini-stats">SPD ${stats.speedMultiplier.toFixed(2)} · PWR ${stats.damageMultiplier.toFixed(2)} · WT ${stats.weight.toFixed(2)}</small>
    </button>`;
}

export function mountMatchSetupFightersScreen(root: HTMLElement): void {
  const setup = loadMatchSetup();
  const saved = listCreatedFighters();
  const defaults = [0, 1, 2, 3].map((i) => getDefaultCreatedFighter(i));
  const roster = saved.length >= 2 ? [...saved, ...defaults.filter((d) => !saved.some((s) => s.id === d.id))] : defaults;

  let p1 = setup.fighters.find((f) => f.playerId === 0)?.fighter ?? roster[0] ?? defaults[0];
  let p2 = setup.fighters.find((f) => f.playerId === 1)?.fighter ?? roster[1] ?? defaults[1];

  const render = () => {
    root.innerHTML = `
      <div class="screen match-setup-fighters">
        <h2>Character Select</h2>
        <p class="hint">Choose fighters for each player.</p>
        <div class="vs-select-row">
          <div class="vs-select-col">
            <h3>Player 1</h3>
            ${roster.map((f) => fighterCard(f, f.id === p1.id, 0)).join("")}
          </div>
          <div class="vs-select-col">
            <h3>Player 2</h3>
            ${roster.map((f) => fighterCard(f, f.id === p2.id, 1)).join("")}
          </div>
        </div>
        <div class="create-actions">
          <button type="button" id="msf-create" class="btn-secondary">Create New Fighter</button>
          <button type="button" id="msf-back" class="btn-secondary">Back to Map Select</button>
          <button type="button" id="msf-continue" class="btn-primary">Continue to Controls Check</button>
        </div>
      </div>
    `;

    const findFighter = (id: string) => roster.find((f) => f.id === id) ?? defaults[0];

    root.querySelectorAll(".fighter-pick").forEach((btn) => {
      btn.addEventListener("click", () => {
        const el = btn as HTMLButtonElement;
        const player = Number(el.dataset.player);
        const fighter = findFighter(el.dataset.id!);
        if (player === 0) p1 = fighter;
        else p2 = fighter;
        render();
      });
    });

    root.querySelector("#msf-create")?.addEventListener("click", () => navigateToHash(APP_ROUTES.createFighter));
    root.querySelector("#msf-back")?.addEventListener("click", () => navigateToHash(APP_ROUTES.matchSetupStage));
    root.querySelector("#msf-continue")?.addEventListener("click", () => {
      saveMatchSetup({
        ...setup,
        fighters: [
          { playerId: 0, fighterId: p1.id, fighter: p1 },
          { playerId: 1, fighterId: p2.id, fighter: p2 },
        ],
      });
      navigateToHash(APP_ROUTES.matchSetupControls);
    });
  };

  render();
}
