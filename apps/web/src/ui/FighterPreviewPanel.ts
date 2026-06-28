import type { CreatedFighter } from "@anime-aggressors/game-core";
import { SIZE_STATS, getDefaultFighterProfile, normalizeDefaultFighterId } from "@anime-aggressors/game-core";
import { ARENA_CLASSES } from "./theme/arenaClasses.ts";

export function renderFighterPreviewPanel(fighter: CreatedFighter | null): string {
  if (!fighter) {
    return `
      <div class="${ARENA_CLASSES.fighterPreviewPanel} cs-preview-panel character-preview-panel">
        <canvas id="cs-preview-canvas" class="cs-preview-canvas character-preview-canvas" width="640" height="320" aria-hidden="true"></canvas>
        <div class="cs-preview-info cs-preview-info--empty">
          <p>Hover a fighter to preview</p>
        </div>
      </div>`;
  }

  const profile = getDefaultFighterProfile(normalizeDefaultFighterId(fighter.id));
  const elementLine = profile
    ? `${profile.elementName} / ${SIZE_STATS[fighter.size].label}`
    : `${fighter.color} / ${SIZE_STATS[fighter.size].label}`;

  return `
    <div class="${ARENA_CLASSES.fighterPreviewPanel} cs-preview-panel character-preview-panel">
      <canvas id="cs-preview-canvas" class="cs-preview-canvas character-preview-canvas" width="640" height="320" aria-hidden="true"></canvas>
      <div class="cs-preview-info">
        <h3 class="cs-preview-name">${fighter.name.toUpperCase()}</h3>
        <p class="cs-preview-element">${elementLine}</p>
        <p class="cs-preview-archetype">${profile?.archetype ?? "Custom Fighter"}</p>
        <p class="cs-preview-signature">Signature: ${profile?.signatureMoveName ?? "Custom Combo"}</p>
        <p class="cs-preview-tagline">"${profile?.shortTagline ?? "Ready for battle."}"</p>
      </div>
    </div>`;
}
