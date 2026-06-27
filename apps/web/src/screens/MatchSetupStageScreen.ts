import { listStages } from "@anime-aggressors/game-core";
import { APP_ROUTES, navigateToHash } from "../routes.js";
import { loadMatchSetup, saveMatchSetup } from "../match/matchSetupSession.js";

const FLAGLINE_ROOM_IDS = [
  "flagline-lunar-base",
  "flagline-lunar-outpost",
  "flagline-center-clash",
  "flagline-solar-outpost",
  "flagline-solar-base",
] as const;

const MATCH_SETUP_STAGE_IDS = [
  "skyline-arena",
  "training-grid",
  "impact-platform",
  "flagline-center-clash",
  "flagline-lunar-outpost",
  "flagline-solar-outpost",
  "flagline-lunar-base",
  "flagline-solar-base",
] as const;

export function mountMatchSetupStageScreen(root: HTMLElement): void {
  const setup = loadMatchSetup();
  const isFlagline = setup.mode === "flaglineClash" || setup.ruleset?.matchType === "flaglineClash";
  const stages = listStages().filter((s) => MATCH_SETUP_STAGE_IDS.includes(s.id as (typeof MATCH_SETUP_STAGE_IDS)[number]));
  let selectedId = setup.stageId ?? stages[0]?.id ?? "skyline-arena";

  const render = () => {
    const selected = stages.find((s) => s.id === selectedId) ?? stages[0];
    root.innerHTML = `
      <div class="screen match-setup-stage">
        <h2>Map Select</h2>
        <p class="hint">${isFlagline ? "Flagline Clash uses a five-room map strip. Center Clash is the starting room." : "Pick the battlefield."}</p>
        ${
          isFlagline
            ? `
        <div class="flagline-strip">
          ${FLAGLINE_ROOM_IDS.map(
            (id) => {
              const s = stages.find((st) => st.id === id);
              return `<div class="flagline-room ${id === "flagline-center-clash" ? "start-room" : ""}">${s?.name ?? id}</div>`;
            },
          ).join("")}
        </div>
        <p class="hint"><small>Flagline map set — select the starting arena below.</small></p>`
            : `<div class="stage-preview placeholder">Stage preview</div>`
        }
        <div class="stage-grid">
          ${stages
            .map(
              (s) => `
            <button type="button" class="stage-card ${s.id === selectedId ? "selected" : ""}" data-id="${s.id}">
              <strong>${s.name}</strong>
              ${s.placeholder ? "<small>placeholder</small>" : ""}
            </button>`,
            )
            .join("")}
        </div>
        <div class="rules-summary">
          <strong>Selected stage:</strong> ${selected?.name ?? "—"}
        </div>
        <div class="create-actions">
          <button type="button" id="mss-back" class="btn-secondary">Back to Rules</button>
          <button type="button" id="mss-continue" class="btn-primary">Continue to Character Select</button>
        </div>
      </div>
    `;

    root.querySelectorAll(".stage-card").forEach((btn) => {
      btn.addEventListener("click", () => {
        selectedId = (btn as HTMLButtonElement).dataset.id!;
        render();
      });
    });

    root.querySelector("#mss-back")?.addEventListener("click", () => navigateToHash(APP_ROUTES.matchSetupRules));
    root.querySelector("#mss-continue")?.addEventListener("click", () => {
      const stage = stages.find((s) => s.id === selectedId);
      if (!stage) return;
      saveMatchSetup({
        ...setup,
        stageId: stage.id,
        stageName: stage.name,
      });
      navigateToHash(APP_ROUTES.matchSetupFighters);
    });
  };

  render();
}
