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
import { renderSetupFlowShell } from "../ui/setup/SetupFlowShell.ts";
import {
  renderRulesPresetCard,
  renderRulesSummaryCard,
  rulesPresetCardFromRuleset,
} from "../ui/rules/RulesPresetCard.ts";
import { ARENA_CLASSES } from "../ui/theme/arenaClasses.ts";

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
    const body = `
      <div class="${ARENA_CLASSES.cardGrid} rules-preset-grid">
        ${presets.map((p) => renderRulesPresetCard(rulesPresetCardFromRuleset(p, p.id === selectedId))).join("")}
        ${renderRulesPresetCard({
          id: "custom",
          title: "CUSTOM RULES",
          description: "Build your own ruleset with damage, launch, and element toggles.",
          icon: "⚙",
          navRoute: APP_ROUTES.customGame,
        })}
        ${renderRulesPresetCard({
          id: "saved",
          title: "SAVED RULESETS",
          description: "Load or edit rulesets saved in your browser.",
          icon: "★",
          navRoute: APP_ROUTES.rulesets,
        })}
      </div>
      ${selected ? renderRulesSummaryCard(selected.name, rulesSummary(selected)) : ""}
    `;

    root.innerHTML = renderSetupFlowShell({
      step: "rules",
      title: "Rules Select",
      subtitle: "Choose how this match is played.",
      body,
      footer: {
        backId: "msr-back",
        backLabel: "Back to Main Menu",
        continueId: "msr-continue",
        continueLabel: "Continue to Map Select",
        extraHtml: `<button type="button" id="msr-edit" class="${ARENA_CLASSES.secondaryBtn}">Edit Custom Rules</button>`,
      },
    });

    root.querySelectorAll(".rules-preset-card[data-id]").forEach((btn) => {
      btn.addEventListener("click", () => {
        selectedId = (btn as HTMLButtonElement).dataset.id!;
        render();
      });
    });

    root.querySelectorAll(".rules-preset-card[data-nav]").forEach((btn) => {
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
