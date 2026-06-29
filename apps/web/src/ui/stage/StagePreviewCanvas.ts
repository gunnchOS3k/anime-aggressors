import { getStageLayout } from "@anime-aggressors/game-core";
import { getStageVisualConfig } from "../../renderer-three/stages/stageVisualConfigs.ts";
import { renderStageMiniMap } from "./StageMiniMap.ts";
import { ARENA_CLASSES } from "../theme/arenaClasses.ts";

export function renderStagePreviewHeroPanel(stageId: string): string {
  const layout = getStageLayout(stageId);
  const visual = getStageVisualConfig(stageId);
  const hazards = layout.hazardsEnabled ? "On" : "Off";
  const competitive = visual.competitive ? "Yes" : "Standard";

  return `<div class="${ARENA_CLASSES.stagePreviewHero} stage-preview-hero setup-hero-panel">
    <canvas id="stage-preview-canvas" class="stage-preview-canvas" width="640" height="360" aria-label="${layout.name} 3D preview"></canvas>
    <div class="stage-preview-hero__info">
      <h2 class="stage-preview-hero__title">${layout.name.toUpperCase()}</h2>
      <p class="stage-preview-hero__vibe">${layout.vibe}</p>
      <div class="stage-preview-hero__minimap-wrap">
        ${renderStageMiniMap(stageId)}
      </div>
      <dl class="stage-preview-hero__meta">
        <div><dt>Modes</dt><dd>${layout.supportedModes.join(", ")}</dd></div>
        <div><dt>Hazards</dt><dd>${hazards}</dd></div>
        <div><dt>Competitive</dt><dd>${competitive}</dd></div>
      </dl>
    </div>
  </div>`;
}
