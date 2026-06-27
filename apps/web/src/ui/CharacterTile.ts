import type { CreatedFighter } from "@anime-aggressors/game-core";
import { ELEMENTS, SIZE_STATS, getDefaultFighterProfile, normalizeDefaultFighterId } from "@anime-aggressors/game-core";
import type { TileState } from "../characterSelect/characterSelectState.js";

export type CharacterTileOptions = {
  fighter: CreatedFighter;
  state: TileState;
  tabIndex?: number;
};

export function renderCharacterTile({ fighter, state, tabIndex = 0 }: CharacterTileOptions): string {
  const profile = getDefaultFighterProfile(normalizeDefaultFighterId(fighter.id));
  const el = ELEMENTS[fighter.color];
  const sizeLabel = SIZE_STATS[fighter.size].label.charAt(0);
  const marker =
    state === "p1" ? '<span class="cs-tile-marker p1">P1</span>' :
    state === "p2" ? '<span class="cs-tile-marker p2">P2</span>' :
    state === "both" ? '<span class="cs-tile-marker both">P1·P2</span>' : "";

  return `
    <button type="button" class="cs-tile cs-tile--${state}" data-fighter-id="${fighter.id}"
      style="--tile-accent:${el.hexColor}" tabindex="${tabIndex}" aria-label="${fighter.name}, ${el.name}, ${SIZE_STATS[fighter.size].label}">
      <span class="cs-tile-portrait" style="background:linear-gradient(135deg, ${el.hexColor}55, ${el.hexColor}22)">
        <span class="cs-tile-initial">${fighter.name.charAt(0)}</span>
      </span>
      <span class="cs-tile-name">${fighter.name}</span>
      <span class="cs-tile-meta">
        <span class="cs-tile-element" style="color:${el.hexColor}">${profile?.elementName ?? el.name}</span>
        <span class="cs-tile-size" title="${SIZE_STATS[fighter.size].label}">${sizeLabel}</span>
      </span>
      ${marker}
    </button>`;
}
