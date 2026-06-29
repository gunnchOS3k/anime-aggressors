import { listStages } from "@anime-aggressors/game-core";
import { APP_ROUTES, navigateToHash } from "../routes.js";
import { loadMatchSetup, saveMatchSetup } from "../match/matchSetupSession.js";
import { renderSetupFlowShell } from "../ui/setup/SetupFlowShell.ts";
import { renderStageSelectGrid } from "../ui/stage/StageSelectGrid.ts";
import { renderStagePreviewHeroPanel } from "../ui/stage/StagePreviewCanvas.ts";
import { createStagePreviewRenderer, type StagePreviewRenderer } from "../renderer-three/stage-preview/StagePreviewRenderer.ts";

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
  let preview: StagePreviewRenderer | null = null;

  const render = () => {
    const summary = `${setup.ruleset?.name ?? "Rules"} · ${stages.find((s) => s.id === selectedId)?.name ?? "Stage"}`;
    const flaglineStrip = isFlagline
      ? `<div class="flagline-strip setup-hero-panel">
          ${FLAGLINE_ROOM_IDS.map((id) => {
            const s = stages.find((st) => st.id === id);
            return `<div class="flagline-room ${id === "flagline-center-clash" ? "start-room" : ""}">${s?.name ?? id}</div>`;
          }).join("")}
        </div>`
      : "";

    const body = `
      ${flaglineStrip}
      <div class="stage-select-layout setup-hero-panel-row stage-select-layout--preview">
        ${renderStagePreviewHeroPanel(selectedId)}
        ${renderStageSelectGrid(stages, selectedId)}
      </div>
    `;

    root.innerHTML = renderSetupFlowShell({
      step: "stage",
      title: "Map Select",
      subtitle: isFlagline ? "Flagline Clash uses a five-room map strip." : "Pick the battlefield.",
      summary,
      body,
      footer: {
        backId: "mss-back",
        backLabel: "Back to Rules",
        continueId: "mss-continue",
        continueLabel: "Continue to Character Select",
      },
    });

    preview?.dispose();
    const canvas = root.querySelector<HTMLCanvasElement>("#stage-preview-canvas");
    if (canvas) {
      preview = createStagePreviewRenderer(canvas);
      preview.setStage(selectedId);
      preview.resize(canvas.clientWidth || 640, canvas.clientHeight || 360);
      preview.start();
    }

    root.querySelectorAll(".stage-select-thumb").forEach((btn) => {
      btn.addEventListener("click", () => {
        selectedId = (btn as HTMLButtonElement).dataset.id!;
        render();
      });
    });

    root.querySelector("#mss-back")?.addEventListener("click", () => {
      preview?.dispose();
      navigateToHash(APP_ROUTES.matchSetupRules);
    });
    root.querySelector("#mss-continue")?.addEventListener("click", () => {
      const stage = stages.find((s) => s.id === selectedId);
      if (!stage) return;
      preview?.dispose();
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
