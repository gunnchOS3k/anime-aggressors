import type { DefaultFighterId } from "@anime-aggressors/game-core";
import { DEFAULT_FIGHTERS, getDefaultCreatedFighter } from "@anime-aggressors/game-core";
import { navigateToHash, APP_ROUTES } from "../routes.ts";
import { saveDerbySetup } from "../modes/impactDummyDerbySetup.ts";
import { ARENA_CLASSES } from "../ui/theme/arenaClasses.ts";
import { renderFighterPortraitHtml } from "../renderer-three/portraits/FighterPortraitFactory.ts";

export function mountImpactDummyDerbyFighterSelectScreen(root: HTMLElement): void {
  let selectedId: DefaultFighterId = DEFAULT_FIGHTERS[0]!.id;

  const render = () => {
    root.innerHTML = `
      <div class="${ARENA_CLASSES.shell} derby-fighter-select setup-shell">
        <h1>Impact Dummy Derby</h1>
        <p class="setup-subtitle">Select your fighter before entering the launch runway.</p>
        <div class="derby-fighter-grid setup-card-grid">
          ${DEFAULT_FIGHTERS.map((f) => `
            <button type="button" class="derby-fighter-card ${f.id === selectedId ? "selected" : ""}" data-id="${f.id}">
              ${renderFighterPortraitHtml(f.id, 72)}
              <span>${f.name}</span>
            </button>
          `).join("")}
        </div>
        <div class="setup-footer">
          <button type="button" id="derby-fs-back" class="${ARENA_CLASSES.secondaryBtn}">← Home</button>
          <button type="button" id="derby-fs-continue" class="${ARENA_CLASSES.primaryCta}">Continue to Derby</button>
        </div>
      </div>
    `;

    root.querySelectorAll(".derby-fighter-card").forEach((btn) => {
      btn.addEventListener("click", () => {
        selectedId = (btn as HTMLButtonElement).dataset.id! as DefaultFighterId;
        render();
      });
    });

    root.querySelector("#derby-fs-back")?.addEventListener("click", () => {
      navigateToHash(APP_ROUTES.home);
    });

    root.querySelector("#derby-fs-continue")?.addEventListener("click", () => {
      const preset = DEFAULT_FIGHTERS.find((f) => f.id === selectedId) ?? DEFAULT_FIGHTERS[0]!;
      const fighter = getDefaultCreatedFighter(DEFAULT_FIGHTERS.findIndex((f) => f.id === preset.id));
      saveDerbySetup({
        fighterId: fighter.id,
        fighterName: fighter.name,
        fighterSize: fighter.size,
        fighterColor: fighter.color,
        stageId: "impact-platform",
        ready: false,
      });
      navigateToHash(APP_ROUTES.impactDummyDerby);
    });
  };

  render();
}
