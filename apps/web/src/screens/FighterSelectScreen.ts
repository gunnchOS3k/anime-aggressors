import type { CreatedFighter } from "@anime-aggressors/game-core";
import { ELEMENTS, SIZE_STATS, getDefaultCreatedFighter } from "@anime-aggressors/game-core";
import { listCreatedFighters } from "../storage/createdFightersStorage.js";
import { navigateTo } from "../router.js";

export type FighterSelectResult = {
  p1Fighter: CreatedFighter;
  p2Fighter: CreatedFighter;
};

export function mountFighterSelectScreen(
  root: HTMLElement,
  onStart: (result: FighterSelectResult) => void,
): void {
  const saved = listCreatedFighters();
  const defaults = [0, 1, 2, 3].map((i) => getDefaultCreatedFighter(i));
  const roster = saved.length >= 2 ? [...saved, ...defaults.filter((d) => !saved.some((s) => s.id === d.id))] : defaults;

  let p1 = roster[0] ?? defaults[0];
  let p2 = roster[1] ?? defaults[1];

  root.innerHTML = `
    <div class="screen fighter-select">
      <h2>Choose Your Fighters</h2>
      <p class="hint">Pick a saved fighter or default. Create more in Create Fighter.</p>
      <div class="vs-select-row">
        <div class="vs-select-col">
          <h3>Player 1</h3>
          ${roster
            .map(
              (f) => `
            <button type="button" class="fighter-pick ${f.id === p1.id ? "selected" : ""}" data-player="0" data-id="${f.id}"
              style="border-color:${ELEMENTS[f.color].hexColor}">
              <strong>${f.name}</strong><br/>
              <small>${SIZE_STATS[f.size].label} · ${ELEMENTS[f.color].name}</small>
            </button>`,
            )
            .join("")}
        </div>
        <div class="vs-select-col">
          <h3>Player 2</h3>
          ${roster
            .map(
              (f) => `
            <button type="button" class="fighter-pick ${f.id === p2.id ? "selected" : ""}" data-player="1" data-id="${f.id}"
              style="border-color:${ELEMENTS[f.color].hexColor}">
              <strong>${f.name}</strong><br/>
              <small>${SIZE_STATS[f.size].label} · ${ELEMENTS[f.color].name}</small>
            </button>`,
            )
            .join("")}
        </div>
      </div>
      <div class="create-actions">
        <button type="button" id="fs-create" class="btn-secondary">Create Fighter</button>
        <button type="button" id="fs-start" class="btn-primary">Start Match</button>
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
      root.querySelectorAll(`.fighter-pick[data-player="${player}"]`).forEach((b) =>
        b.classList.remove("selected"),
      );
      el.classList.add("selected");
    });
  });

  root.querySelector("#fs-create")?.addEventListener("click", () => navigateTo("create-fighter"));
  root.querySelector("#fs-start")?.addEventListener("click", () => {
    onStart({ p1Fighter: p1, p2Fighter: p2 });
  });
}

/** @deprecated use mountFighterSelectScreen */
export const showCharacterSelect = mountFighterSelectScreen;
export type CharacterSelectResult = FighterSelectResult;
