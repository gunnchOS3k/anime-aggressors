import { getStageLayout, STAGE_WIDTH, FLOOR_Y } from "@anime-aggressors/game-core";
import type { StageLayoutDef } from "@anime-aggressors/game-core";

export type StagePreviewOptions = {
  stageId: string;
  showHazards?: boolean;
};

function renderMiniMap(layout: StageLayoutDef): string {
  const mapW = 200;
  const mapH = 80;
  const scaleX = mapW / STAGE_WIDTH;
  const scaleY = mapH / (FLOOR_Y + 40);

  const platforms = layout.platforms
    .map((p) => {
      const x = p.x * scaleX;
      const y = mapH - p.y * scaleY - p.height * scaleY;
      const w = p.width * scaleX;
      const h = Math.max(4, p.height * scaleY);
      const isMain = p.id === layout.mainPlatformId;
      return `<rect x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="${w.toFixed(1)}" height="${h.toFixed(1)}" class="stage-minimap-plat ${isMain ? "main" : ""}" />`;
    })
    .join("");

  return `
    <svg class="stage-minimap" viewBox="0 0 ${mapW} ${mapH}" aria-hidden="true">
      <rect class="stage-minimap-bg" x="0" y="0" width="${mapW}" height="${mapH}" />
      ${platforms}
    </svg>`;
}

export function renderStagePreviewPanel({ stageId, showHazards = true }: StagePreviewOptions): string {
  const layout = getStageLayout(stageId);
  const modes = layout.supportedModes.join(", ");

  return `
    <div class="stage-preview-panel">
      <div class="stage-preview-header">
        <h3>${layout.name}</h3>
        ${showHazards && layout.hazardsEnabled ? '<span class="stage-hazard-icon" title="Hazards enabled">⚠</span>' : ""}
      </div>
      <p class="stage-vibe">${layout.vibe}</p>
      ${renderMiniMap(layout)}
      <div class="stage-meta">
        <span class="stage-modes"><strong>Modes:</strong> ${modes}</span>
        <span class="stage-platform-count">${layout.platforms.length} platforms</span>
      </div>
    </div>`;
}

export function layoutPlatformIds(stageId: string): string[] {
  return getStageLayout(stageId).platforms.map((p) => p.id);
}
