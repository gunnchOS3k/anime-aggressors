import type { CreatedFighter } from "@anime-aggressors/game-core";
import { ELEMENTS, SIZE_STATS, getDefaultFighterProfile, normalizeDefaultFighterId } from "@anime-aggressors/game-core";
import { renderFighterPortraitHtml } from "../renderer-three/portraits/FighterPortraitFactory.ts";

export function renderPlayerSelectionPanel(
  player: 0 | 1,
  fighter: CreatedFighter | null,
  active: boolean,
): string {
  const label = player === 0 ? "Player 1" : "Player 2";
  if (!fighter) {
    return `
      <div class="cs-player-panel cs-player-panel--empty ${active ? "active" : ""}" data-player-slot="${player}">
        <h4>${label}</h4>
        <div class="cs-panel-portrait cs-panel-portrait--empty">?</div>
        <p class="cs-panel-empty">Select a fighter</p>
      </div>`;
  }

  const profile = getDefaultFighterProfile(normalizeDefaultFighterId(fighter.id));
  const el = ELEMENTS[fighter.color];

  return `
    <button type="button" class="cs-player-panel ${active ? "active" : ""}" data-player-slot="${player}">
      <h4>${label}</h4>
      <div class="cs-panel-portrait" style="border-color:${el.hexColor}">
        ${renderFighterPortraitHtml(fighter.id, 88)}
      </div>
      <div class="cs-panel-chip" style="border-color:${el.hexColor}">
        <strong>${fighter.name}</strong>
        <span>${profile?.elementName ?? el.name} · ${SIZE_STATS[fighter.size].label}</span>
      </div>
    </button>`;
}
