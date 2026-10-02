import type { CreatedFighter, FighterBodyVariant } from "@anime-aggressors/game-core";
import { ELEMENTS, SIZE_STATS, getDefaultFighterProfile, getFighterGameplayProfile, normalizeDefaultFighterId } from "@anime-aggressors/game-core";
import type { TileState } from "../characterSelect/characterSelectState.js";
import { renderFighterPortraitHtml } from "../renderer-three/portraits/FighterPortraitFactory.ts";

export type CharacterTileOptions = {
  fighter: CreatedFighter;
  state: TileState;
  tabIndex?: number;
};

/** Dual presentation icons on each of the 7 roster tiles (not 14 top-level tiles). */
function dualFormPreview(fighterId: string): string {
  return `
    <span class="cs-tile-dual" aria-hidden="true">
      <span class="cs-tile-dual-icon cs-tile-dual-icon--male" title="Male presentation">${renderFighterPortraitHtml(fighterId, 28)}</span>
      <span class="cs-tile-dual-icon cs-tile-dual-icon--female" title="Female presentation">${renderFighterPortraitHtml(fighterId, 28)}</span>
    </span>`;
}

export function renderCharacterTile({ fighter, state, tabIndex = 0 }: CharacterTileOptions): string {
  const profile = getDefaultFighterProfile(normalizeDefaultFighterId(fighter.id));
  const gameplay = getFighterGameplayProfile(fighter.id);
  const rosterBadge =
    gameplay?.status === "production"
      ? '<span class="cs-tile-badge cs-tile-badge--production">Production</span>'
      : gameplay?.status === "preview"
        ? '<span class="cs-tile-badge cs-tile-badge--preview">Preview</span>'
        : "";
  const el = ELEMENTS[fighter.color];
  const sizeLabel = SIZE_STATS[fighter.size].label;
  const marker =
    state === "p1" ? '<span class="cs-tile-marker p1">P1</span>' :
    state === "p2" ? '<span class="cs-tile-marker p2">P2</span>' :
    state === "both" ? '<span class="cs-tile-marker both">P1·P2</span>' : "";

  return `
    <button type="button" class="character-portrait-tile cs-tile cs-tile--${state}" data-fighter-id="${fighter.id}"
      style="--tile-accent:${el.hexColor}" tabindex="${tabIndex}" aria-label="${fighter.name}, ${el.name}, ${sizeLabel}, male and female presentations">
      <span class="cs-tile-portrait character-portrait-frame">
        ${renderFighterPortraitHtml(fighter.id, 64)}
      </span>
      ${dualFormPreview(fighter.id)}
      <span class="cs-tile-name">${fighter.name}</span>
      ${rosterBadge}
      <span class="cs-tile-meta">
        <span class="cs-tile-element" style="color:${el.hexColor}">${profile?.elementName ?? el.name}</span>
        <span class="cs-tile-size" title="${sizeLabel}">${sizeLabel.charAt(0)}</span>
      </span>
      ${marker}
    </button>`;
}

export function bodyVariantLabel(variant: FighterBodyVariant): string {
  return variant === "female" ? "Female" : "Male";
}
