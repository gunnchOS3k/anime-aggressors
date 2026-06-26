import type { CreatedFighter } from "@anime-aggressors/game-core";
import { getActiveRuleset } from "../storage/rulesetStorage.js";
import { getProfileForSlot } from "../storage/inputProfileStorage.js";
import { navigateTo } from "../router.js";

export function mountControlsCheckScreen(
  root: HTMLElement,
  fighters: { p1: CreatedFighter; p2: CreatedFighter },
  onStart: () => void,
): void {
  const ruleset = getActiveRuleset();
  const p1Profile = getProfileForSlot(1);
  const p2Profile = getProfileForSlot(2);

  root.innerHTML = `
    <div class="screen controls-check">
      <h2>Controls Check</h2>
      <p class="hint">Confirm fighters, rules, and control profiles before battle.</p>
      <div class="check-grid">
        <div><strong>P1</strong><br/>${fighters.p1.name}<br/><small>${p1Profile.name} (${p1Profile.deviceType})</small></div>
        <div><strong>P2</strong><br/>${fighters.p2.name}<br/><small>${p2Profile.name} (${p2Profile.deviceType})</small></div>
      </div>
      <div class="rules-summary">
        <strong>Rules:</strong> ${ruleset.name} · ${ruleset.matchType} · ${ruleset.stocks} stock ·
        ${ruleset.timerSeconds ? `${ruleset.timerSeconds}s timer` : "no timer"} ·
        damage ${ruleset.damageRatio}x · launch ${ruleset.launchRatio}x · elements ${ruleset.elementMode}
      </div>
      <div class="create-actions">
        <button type="button" id="cc-controls" class="btn-secondary">Edit Controls</button>
        <button type="button" id="cc-back" class="btn-secondary">Back</button>
        <button type="button" id="cc-start" class="btn-primary">Start Battle</button>
      </div>
    </div>
  `;

  root.querySelector("#cc-controls")?.addEventListener("click", () => navigateTo("controls"));
  root.querySelector("#cc-back")?.addEventListener("click", () => navigateTo("fighter-select"));
  root.querySelector("#cc-start")?.addEventListener("click", onStart);
}
