import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  createInitialGameState,
  gameConfigFromRuleset,
  DEFAULT_RULESET,
  getDefaultCreatedFighter,
} from "@anime-aggressors/game-core";
import { renderWinnerHero, renderResultsScoreboard, renderResultsActions } from "../src/ui/results/WinnerHero.ts";

describe("match results presentation", () => {
  it("renders winner hero with WINNER label", () => {
    const f0 = getDefaultCreatedFighter(0);
    const f1 = getDefaultCreatedFighter(1);
    const config = gameConfigFromRuleset(DEFAULT_RULESET, [f0, f1], 99);
    const state = createInitialGameState(config);
    state.winnerId = 0;
    const html = renderWinnerHero(state);
    assert.match(html, /WINNER/);
    assert.match(html, /EMBER VALE/i);
    assert.match(html, /Flame Victory/);
    assert.match(html, /results-winner-canvas/);
  });

  it("scoreboard lists fighters with stats", () => {
    const f0 = getDefaultCreatedFighter(0);
    const f1 = getDefaultCreatedFighter(1);
    const config = gameConfigFromRuleset(DEFAULT_RULESET, [f0, f1], 99);
    const state = createInitialGameState(config);
    state.winnerId = 0;
    const html = renderResultsScoreboard(state);
    assert.match(html, /results-scoreboard/);
    assert.match(html, /Ember Vale/);
    assert.match(html, /Rook Ironside/);
  });

  it("actions include rematch, change stage, and home", () => {
    const html = renderResultsActions(false);
    assert.match(html, /vs-rematch/);
    assert.match(html, /vs-change-stage/);
    assert.match(html, /vs-menu/);
  });
});
