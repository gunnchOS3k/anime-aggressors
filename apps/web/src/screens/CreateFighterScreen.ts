import type { CreatedFighter, FighterColor, FighterSize } from "@anime-aggressors/game-core";
import {
  ELEMENTS,
  SIZE_STATS,
  previewFighterStats,
  DEFAULT_FIGHTER_NAME,
} from "@anime-aggressors/game-core";
import {
  createAndSaveFighter,
  deleteCreatedFighter,
  listCreatedFighters,
  saveCreatedFighter,
} from "../storage/createdFightersStorage.js";
import { navigateTo } from "../router.js";

const SIZES: FighterSize[] = ["small", "medium", "large"];
const COLORS: FighterColor[] = [
  "red",
  "orange",
  "yellow",
  "green",
  "blue",
  "indigo",
  "violet",
];

export function mountCreateFighterScreen(
  root: HTMLElement,
  options: { editId?: string; onUseInMatch?: (fighter: CreatedFighter) => void } = {},
): void {
  const existing = options.editId
    ? listCreatedFighters().find((f) => f.id === options.editId)
    : null;

  let name = existing?.name ?? "";
  let size: FighterSize = existing?.size ?? "medium";
  let color: FighterColor = existing?.color ?? "red";

  const render = () => {
    const preview = previewFighterStats(size, color);
    const el = ELEMENTS[color];

    root.innerHTML = `
      <div class="screen create-fighter">
        <div class="screen-toolbar">
          <button type="button" id="cf-back" class="btn-tertiary">← Main Menu</button>
          <h2>Create Fighter</h2>
        </div>

        <div class="create-grid">
          <section class="create-panel">
            <label class="field-label">Fighter Name</label>
            <input id="cf-name" type="text" maxlength="24" placeholder="${DEFAULT_FIGHTER_NAME}" value="${name}" />

            <label class="field-label">Size Class</label>
            <div class="btn-row size-row">
              ${SIZES.map(
                (s) => `
                <button type="button" class="size-btn ${s === size ? "selected" : ""}" data-size="${s}">
                  ${SIZE_STATS[s].label}
                </button>`,
              ).join("")}
            </div>
            <p class="hint">Small = faster but lighter · Medium = balanced · Large = slower but stronger</p>

            <label class="field-label">Element Color (ROYGBIV)</label>
            <div class="color-row">
              ${COLORS.map(
                (c) => `
                <button type="button" class="color-btn ${c === color ? "selected" : ""}" data-color="${c}"
                  style="background:${ELEMENTS[c].hexColor}" title="${ELEMENTS[c].name}"></button>`,
              ).join("")}
            </div>
          </section>

          <section class="preview-panel">
            <h3>${el.name} Element</h3>
            <p>${el.description}</p>
            <ul class="stat-preview">
              <li><strong>Speed:</strong> ${preview.speed}</li>
              <li><strong>Power:</strong> ${preview.power}</li>
              <li><strong>Weight:</strong> ${preview.weight}</li>
              <li><strong>Jump:</strong> ${preview.jump}</li>
              <li><strong>Element:</strong> ${preview.element}</li>
              <li><strong>Passive:</strong> ${preview.passive}</li>
              <li><strong>Special:</strong> ${preview.special}</li>
            </ul>
            <div class="fighter-preview-silhouette" style="--fighter-color:${el.hexColor}; --fighter-scale:${SIZE_STATS[size].hurtboxScale}"></div>
          </section>
        </div>

        <div class="create-actions">
          <button type="button" id="cf-save" class="btn-primary">Save Fighter</button>
          <button type="button" id="cf-use" class="btn-secondary">Use Fighter in Match</button>
          <button type="button" id="cf-reset" class="btn-tertiary">Reset</button>
          ${existing ? `<button type="button" id="cf-delete" class="btn-danger">Delete</button>` : ""}
        </div>

        ${
          listCreatedFighters().length
            ? `<section class="saved-list"><h3>Saved Fighters</h3><ul>${listCreatedFighters()
                .map(
                  (f) =>
                    `<li><button type="button" class="load-fighter" data-id="${f.id}">${f.name} (${SIZE_STATS[f.size].label} ${ELEMENTS[f.color].name})</button></li>`,
                )
                .join("")}</ul></section>`
            : ""
        }
      </div>
    `;

    root.querySelector("#cf-back")?.addEventListener("click", () => navigateTo("home"));
    root.querySelector("#cf-name")?.addEventListener("input", (e) => {
      name = (e.target as HTMLInputElement).value;
    });
    root.querySelectorAll(".size-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        size = (btn as HTMLButtonElement).dataset.size as FighterSize;
        render();
      });
    });
    root.querySelectorAll(".color-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        color = (btn as HTMLButtonElement).dataset.color as FighterColor;
        render();
      });
    });
    root.querySelector("#cf-reset")?.addEventListener("click", () => {
      name = "";
      size = "medium";
      color = "red";
      render();
    });
    root.querySelector("#cf-save")?.addEventListener("click", () => {
      const fighter = existing
        ? saveCreatedFighter({ ...existing, name: name || DEFAULT_FIGHTER_NAME, size, color, updatedAt: new Date().toISOString() })
        : createAndSaveFighter({ name: name || DEFAULT_FIGHTER_NAME, size, color });
      if (options.onUseInMatch) {
        options.onUseInMatch(fighter);
      } else {
        render();
      }
    });
    root.querySelector("#cf-use")?.addEventListener("click", () => {
      const fighter = createAndSaveFighter({ name: name || DEFAULT_FIGHTER_NAME, size, color });
      options.onUseInMatch?.(fighter);
      navigateTo("match");
    });
    root.querySelector("#cf-delete")?.addEventListener("click", () => {
      if (existing) {
        deleteCreatedFighter(existing.id);
        navigateTo("home");
      }
    });
    root.querySelectorAll(".load-fighter").forEach((btn) => {
      btn.addEventListener("click", () => {
        const id = (btn as HTMLButtonElement).dataset.id!;
        const f = listCreatedFighters().find((x) => x.id === id);
        if (f) {
          name = f.name;
          size = f.size;
          color = f.color;
          render();
        }
      });
    });
  };

  render();
}
