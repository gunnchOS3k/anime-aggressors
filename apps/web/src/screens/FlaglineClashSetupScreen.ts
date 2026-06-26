import { FLAGLINE_DEFAULTS } from "@anime-aggressors/game-core";
import { navigateTo } from "../router.js";

export function mountFlaglineClashSetupScreen(root: HTMLElement): void {
  root.innerHTML = `
    <div class="screen flagline-setup">
      <div class="screen-toolbar">
        <button type="button" id="fls-back" class="btn-secondary">← Home</button>
        <h2>Flagline Clash</h2>
      </div>
      <p class="hint">Team territory war across five rooms. Capture the Flag Core and push the frontline toward the enemy base.</p>
      <div class="flagline-flow">
        <code>Lunar Base ← Lunar Outpost ← Center Clash → Solar Outpost → Solar Base</code>
      </div>
      <ul class="playtest-steps">
        <li>Solar pushes left · Lunar pushes right</li>
        <li>Win a room to advance the frontline</li>
        <li>Capture the enemy base room to win the game</li>
        <li>Default: P1 + Bot vs P2 + Bot for local testing</li>
      </ul>
      <div class="create-actions">
        <button type="button" id="fls-teams" class="btn-primary">Choose Teams →</button>
        <button type="button" id="fls-custom" class="btn-secondary">Custom Game Rules</button>
      </div>
    </div>
  `;

  root.querySelector("#fls-back")?.addEventListener("click", () => navigateTo("home"));
  root.querySelector("#fls-teams")?.addEventListener("click", () => navigateTo("flagline-teams"));
  root.querySelector("#fls-custom")?.addEventListener("click", () => navigateTo("custom-game"));
}

export function getDefaultFlaglineConfig() {
  return { ...FLAGLINE_DEFAULTS };
}
