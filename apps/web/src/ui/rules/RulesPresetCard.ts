import type { GameRuleset } from "@anime-aggressors/game-core";
import { ARENA_CLASSES } from "../theme/arenaClasses.ts";

export type RulesPresetCardData = {
  id: string;
  title: string;
  description: string;
  icon: string;
  selected?: boolean;
  navRoute?: string;
};

const PRESET_COPY: Record<string, { title: string; description: string; icon: string }> = {
  "friendly-3-stock": {
    title: "3 STOCK BATTLE",
    description: "Classic platform-fighter rules. Knock rivals out before your stocks run dry.",
    icon: "⚔",
  },
  "quick-2-minute": {
    title: "TIMED BATTLE",
    description: "Two minutes on the clock — highest score when time expires wins.",
    icon: "⏱",
  },
  "stamina-100": {
    title: "STAMINA BATTLE",
    description: "HP pools instead of stocks. Drain your rival's stamina to zero.",
    icon: "♥",
  },
  "flagline-clash-2v2": {
    title: "FLAGLINE CLASH",
    description: "Team capture mode across a five-room map strip.",
    icon: "🚩",
  },
};

export function rulesPresetCardFromRuleset(r: GameRuleset, selected: boolean): RulesPresetCardData {
  const copy = PRESET_COPY[r.id] ?? {
    title: r.name.toUpperCase(),
    description: `${r.matchType} · ${r.stocks} stock · ${r.playerCount}P`,
    icon: "◆",
  };
  return { id: r.id, ...copy, selected };
}

export function renderRulesPresetCard(card: RulesPresetCardData): string {
  const attrs = card.navRoute
    ? `data-nav="${card.navRoute}"`
    : `data-id="${card.id}"`;
  return `<button type="button" class="rules-preset-card ${card.selected ? "selected" : ""} ${ARENA_CLASSES.cardGrid}-item" ${attrs}>
    <span class="rules-preset-card__icon">${card.icon}</span>
    <strong class="rules-preset-card__title">${card.title}</strong>
    <small class="rules-preset-card__desc">${card.description}</small>
  </button>`;
}

export function renderRulesSummaryCard(name: string, summary: string): string {
  return `<div class="rules-summary-card setup-hero-panel">
    <span class="rules-summary-card__label">Selected Rules</span>
    <strong>${name}</strong>
    <p>${summary}</p>
  </div>`;
}
