import { getStage, listProductionStageIds, listStages } from "@anime-aggressors/game-core";
import { APP_ROUTES, navigateToHash } from "../routes.js";
import {
  applySetupToMatchSession,
  loadMatchSetup,
  saveMatchSetup,
} from "../match/matchSetupSession.ts";
import { renderStageSelectGrid } from "../ui/stage/StageSelectGrid.ts";
import { renderStagePreviewHeroPanel } from "../ui/stage/StagePreviewCanvas.ts";
import { createStagePreviewRenderer, type StagePreviewRenderer } from "../renderer-three/stage-preview/StagePreviewRenderer.ts";
import { navigateHome } from "../router.js";
import { ARENA_CLASSES } from "../ui/theme/arenaClasses.ts";

export function mountDemoStageSelectScreen(root: HTMLElement): void {
  const setup = loadMatchSetup();
  const productionIds = listProductionStageIds();
  const stages = listStages().filter((s) => productionIds.includes(s.id as (typeof productionIds)[number]));
  let selectedId =
    setup.stageId && productionIds.includes(setup.stageId as (typeof productionIds)[number])
      ? setup.stageId
      : stages[0]?.id ?? "skyline-arena";
  let preview: StagePreviewRenderer | null = null;

  const render = () => {
    root.innerHTML = `
      <div class="screen demo-stage-select" data-testid="demo-stage-select">
        <div class="screen-toolbar">
          <button type="button" id="dss-back" class="btn-secondary">← Home</button>
          <h2>Stage Select</h2>
        </div>
        <p class="hint">Production demo stages for the public vertical slice.</p>
        <div class="stage-select-layout setup-hero-panel-row">
          ${renderStagePreviewHeroPanel(selectedId)}
          ${renderStageSelectGrid(stages, selectedId)}
        </div>
        <div class="demo-stage-actions">
          <button type="button" id="dss-battle" class="${ARENA_CLASSES.primaryCta}">Ready Check</button>
          <button type="button" id="dss-fighters" class="${ARENA_CLASSES.secondaryBtn}">Change fighters</button>
        </div>
      </div>
    `;

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

    root.querySelector("#dss-back")?.addEventListener("click", () => {
      preview?.dispose();
      navigateHome();
    });

    const persistStage = () => {
      const stage = getStage(selectedId);
      const next = {
        ...setup,
        stageId: stage.id,
        stageName: stage.name,
        ruleset: setup.ruleset
          ? { ...setup.ruleset, stageId: stage.id }
          : setup.ruleset,
      };
      saveMatchSetup(next);
      applySetupToMatchSession(next);
    };

    root.querySelector("#dss-battle")?.addEventListener("click", () => {
      persistStage();
      preview?.dispose();
      navigateToHash(APP_ROUTES.matchSetupControls);
    });

    root.querySelector("#dss-fighters")?.addEventListener("click", () => {
      persistStage();
      preview?.dispose();
      navigateToHash(APP_ROUTES.fighterSelect);
    });
  };

  render();
}
