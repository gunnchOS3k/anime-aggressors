import type { StageDef } from "@anime-aggressors/game-core";
import { getStageLayout } from "@anime-aggressors/game-core";
import { getStageVisualConfig } from "../../renderer-three/stages/stageVisualConfigs.ts";
import { ARENA_CLASSES } from "../theme/arenaClasses.ts";
import { renderStageMiniMap } from "./StageMiniMap.ts";

export function renderStageSelectGrid(stages: StageDef[], selectedId: string): string {
  return `<div class="stage-select-grid setup-card-grid" role="listbox" aria-label="Stage selection">
    ${stages
      .map((s) => {
        const layout = getStageLayout(s.id);
        const visual = getStageVisualConfig(s.id);
        return `<button type="button" class="stage-select-thumb ${s.id === selectedId ? "selected" : ""}" data-id="${s.id}" role="option" aria-selected="${s.id === selectedId}">
          <span class="stage-select-thumb__name">${s.name}</span>
          ${visual.competitive ? '<span class="stage-badge">Competitive</span>' : ""}
        </button>`;
      })
      .join("")}
  </div>`;
}

export function renderStagePreviewHero(stageId: string): string {
  const layout = getStageLayout(stageId);
  const visual = getStageVisualConfig(stageId);
  const hazards = layout.hazardsEnabled ? "On" : "Off";
  const competitive = visual.competitive ? "Yes" : "Standard";
  return `<div class="${ARENA_CLASSES.stagePreviewHero} setup-hero-panel">
    <h2 class="stage-preview-hero__title">${layout.name.toUpperCase()}</h2>
    <p class="stage-preview-hero__vibe">${layout.vibe}</p>
    ${renderStageMiniMap(stageId)}
    <dl class="stage-preview-hero__meta">
      <div><dt>Modes</dt><dd>${layout.supportedModes.join(", ")}</dd></div>
      <div><dt>Hazards</dt><dd>${hazards}</dd></div>
      <div><dt>Competitive</dt><dd>${competitive}</dd></div>
      <div><dt>Platforms</dt><dd>${layout.platforms.length}</dd></div>
    </dl>
  </div>`;
}

export function renderStageInfoPanel(stageId: string): string {
  const layout = getStageLayout(stageId);
  return `<aside class="stage-info-panel">
    <h3>${layout.name}</h3>
    <p>${layout.vibe}</p>
  </aside>`;
}
