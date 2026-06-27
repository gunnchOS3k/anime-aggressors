import type { GameRuleset } from "@anime-aggressors/game-core";
import { RULESET_PRESETS } from "@anime-aggressors/game-core";
import { listRulesets, setActiveRulesetId } from "../storage/rulesetStorage.js";
import { APP_ROUTES, navigateToHash } from "../routes.js";
import {
  loadMatchSetup,
  saveMatchSetup,
  type MatchSetupMode,
  type MatchSetupSession,
} from "../match/matchSetupSession.js";

const PRESET_IDS = [
  "friendly-3-stock",
  "quick-2-minute",
  "stamina-100",
  "flagline-clash-2v2",
] as const;

function rulesSummary(r: GameRuleset): string {
  const timer = r.timerSeconds ? `${r.timerSeconds}s` : "no timer";
  return `${r.matchType} · ${r.stocks} stock · ${timer} · ${r.playerCount}P`;
}

export function mountMatchSetupRulesScreen(root: HTMLElement): void {
  const setup = loadMatchSetup();
  const allRulesets = listRulesets();
  const presets = PRESET_IDS.map((id) => allRulesets.find((r) => r.id === id)).filter(
    (r): r is GameRuleset => !!r,
  );
  let selectedId = setup.rulesetId ?? presets[0]?.id ?? RULESET_PRESETS[0].id;

  const render = () => {
    const selected = allRulesets.find((r) => r.id === selectedId) ?? presets[0];
    root.innerHTML = `
      <div class="screen match-setup-rules">
        <h2>Rules Select</h2>
        <p class="hint">Choose how this match is played.</p>
        <div class="preset-grid">
          ${presets
            .map(
              (p) => `
            <button type="button" class="preset-card ${p.id === selectedId ? "selected" : ""}" data-id="${p.id}">
              <strong>${p.name}</strong>
              <small>${rulesSummary(p)}</small>
            </button>`,
            )
            .join("")}
          <button type="button" class="preset-card" data-nav="${APP_ROUTES.customGame}">
            <strong>Custom Rules</strong>
            <small>Build your own ruleset</small>
          </button>
          <button type="button" class="preset-card" data-nav="${APP_ROUTES.rulesets}">
            <strong>Saved Rulesets</strong>
            <small>Load or edit saved presets</small>
          </button>
        </div>
        <div class="rules-summary">
          <strong>Selected:</strong> ${selected?.name ?? "—"} — ${selected ? rulesSummary(selected) : ""}
        </div>
        <div class="create-actions">
          <button type="button" id="msr-back" class="btn-secondary">Back to Main Menu</button>
          <button type="button" id="msr-edit" class="btn-secondary">Edit Custom Rules</button>
          <button type="button" id="msr-continue" class="btn-primary">Continue to Map Select</button>
        </div>
      </div>
    `;

    root.querySelectorAll(".preset-card[data-id]").forEach((btn) => {
      btn.addEventListener("click", () => {
        selectedId = (btn as HTMLButtonElement).dataset.id!;
        render();
      });
    });

    root.querySelectorAll(".preset-card[data-nav]").forEach((btn) => {
      btn.addEventListener("click", () => {
        navigateToHash((btn as HTMLButtonElement).dataset.nav!);
      });
    });

    root.querySelector("#msr-back")?.addEventListener("click", () => navigateToHash(APP_ROUTES.home));
    root.querySelector("#msr-edit")?.addEventListener("click", () => navigateToHash(APP_ROUTES.customGame));
    root.querySelector("#msr-continue")?.addEventListener("click", () => {
      const ruleset = allRulesets.find((r) => r.id === selectedId);
      if (!ruleset) return;
      const mode = ruleset.matchType as MatchSetupMode;
      const next: MatchSetupSession = {
        ...setup,
        rulesetId: ruleset.id,
        ruleset: { ...ruleset },
        playerCount: ruleset.playerCount,
        mode,
        stageId: ruleset.stageId,
      };
      saveMatchSetup(next);
      setActiveRulesetId(ruleset.id);
      navigateToHash(APP_ROUTES.matchSetupStage);
    });
  };

  render();
}
