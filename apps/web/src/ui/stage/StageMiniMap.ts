import { getStageLayout, STAGE_WIDTH, FLOOR_Y } from "@anime-aggressors/game-core";

export function renderStageMiniMap(stageId: string): string {
  const layout = getStageLayout(stageId);
  const mapW = 280;
  const mapH = 100;
  const scaleX = mapW / STAGE_WIDTH;
  const scaleY = mapH / (FLOOR_Y + 40);

  const platforms = layout.platforms
    .map((p) => {
      const x = p.x * scaleX;
      const y = mapH - p.y * scaleY - p.height * scaleY;
      const w = p.width * scaleX;
      const h = Math.max(5, p.height * scaleY);
      const isMain = p.id === layout.mainPlatformId;
      return `<rect x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="${w.toFixed(1)}" height="${h.toFixed(1)}" class="stage-minimap-plat ${isMain ? "main" : ""}" />`;
    })
    .join("");

  return `<svg class="stage-minimap stage-minimap--hero" viewBox="0 0 ${mapW} ${mapH}" aria-hidden="true">
    <rect class="stage-minimap-bg" x="0" y="0" width="${mapW}" height="${mapH}" />
    ${platforms}
  </svg>`;
}
