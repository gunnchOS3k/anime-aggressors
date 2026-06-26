import {
  deleteRuleset,
  duplicateRuleset,
  getActiveRulesetId,
  listRulesets,
  resetRulesetsToDefaults,
  setActiveRulesetId,
} from "../storage/rulesetStorage.js";
import { navigateTo } from "../router.js";
import { setMatchRuleset } from "../match/matchSession.js";

export function mountRulesetSelectScreen(root: HTMLElement): void {
  const render = () => {
    const activeId = getActiveRulesetId();
    const rulesets = listRulesets();

    root.innerHTML = `
      <div class="screen ruleset-select">
        <div class="screen-toolbar">
          <button type="button" id="rs-back" class="btn-secondary">← Custom Game</button>
          <h2>Saved Rules</h2>
        </div>
        <p class="hint">Pick a ruleset preset or your saved custom rules.</p>
        <div class="ruleset-list">
          ${rulesets
            .map(
              (r) => `
            <div class="ruleset-card ${r.id === activeId ? "selected" : ""}" data-id="${r.id}">
              <strong>${r.name}</strong>
              <small>${r.matchType} · ${r.playerCount}P · ${r.stocks} stock · ${r.timerSeconds ? `${r.timerSeconds}s` : "no timer"}</small>
              <div class="ruleset-actions">
                <button type="button" class="btn-secondary rs-use" data-id="${r.id}">Use</button>
                <button type="button" class="btn-tertiary rs-dup" data-id="${r.id}">Duplicate</button>
                <button type="button" class="btn-tertiary rs-del" data-id="${r.id}">Delete</button>
              </div>
            </div>`,
            )
            .join("")}
        </div>
        <div class="create-actions">
          <button type="button" id="rs-reset" class="btn-tertiary">Reset to Defaults</button>
        </div>
      </div>
    `;

    root.querySelector("#rs-back")?.addEventListener("click", () => navigateTo("custom-game"));
    root.querySelector("#rs-reset")?.addEventListener("click", () => {
      resetRulesetsToDefaults();
      render();
    });
    root.querySelectorAll(".rs-use").forEach((btn) => {
      btn.addEventListener("click", () => {
        const id = (btn as HTMLButtonElement).dataset.id!;
        setActiveRulesetId(id);
        const ruleset = listRulesets().find((r) => r.id === id);
        if (ruleset) setMatchRuleset(ruleset);
        navigateTo("custom-game");
      });
    });
    root.querySelectorAll(".rs-dup").forEach((btn) => {
      btn.addEventListener("click", () => {
        duplicateRuleset((btn as HTMLButtonElement).dataset.id!);
        render();
      });
    });
    root.querySelectorAll(".rs-del").forEach((btn) => {
      btn.addEventListener("click", () => {
        deleteRuleset((btn as HTMLButtonElement).dataset.id!);
        render();
      });
    });
  };

  render();
}
