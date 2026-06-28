import type { CreatedFighter } from "@anime-aggressors/game-core";
import { renderFighterPortraitHtml } from "../../renderer-three/portraits/FighterPortraitFactory.ts";
import { ARENA_CLASSES } from "../theme/arenaClasses.ts";

export function renderPlayerLoadoutCard(
  label: string,
  fighter: CreatedFighter | null,
  profileName: string,
  active?: boolean,
): string {
  if (!fighter) {
    return `<div class="player-loadout-card player-loadout-card--empty ${active ? "active" : ""}">
      <h3>${label}</h3>
      <p>Select a fighter</p>
    </div>`;
  }
  return `<div class="player-loadout-card ${active ? "active" : ""}">
    <h3>${label}</h3>
    ${renderFighterPortraitHtml(fighter.id, 96)}
    <strong>${fighter.name}</strong>
    <small>${profileName}</small>
  </div>`;
}

export function renderRulesStageSummary(rulesName: string, stageName: string): string {
  return `<div class="rules-stage-summary setup-hero-panel">
    <div><span>Rules</span><strong>${rulesName}</strong></div>
    <div><span>Stage</span><strong>${stageName}</strong></div>
  </div>`;
}

export function renderVersusConfirmPanel(p1Html: string, p2Html: string, summaryHtml: string): string {
  return `<div class="${ARENA_CLASSES.versusConfirm}">
    <div class="versus-confirm-panel__fighters">
      ${p1Html}
      <div class="versus-confirm-panel__vs">VS</div>
      ${p2Html}
    </div>
    ${summaryHtml}
  </div>`;
}
