import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  DEFAULT_RULESET,
  RULESET_PRESETS,
  validateRuleset,
  gameConfigFromRuleset,
  elementGameplayEnabled,
  elementVisualsEnabled,
  rulesetToMatchDurationFrames,
  effectivePlayerCount,
} from "../src/rulesets.js";
import { getDefaultCreatedFighter } from "../src/createdFighter.js";

describe("rulesets", () => {
  it("default ruleset is valid", () => {
    assert.ok(validateRuleset(DEFAULT_RULESET));
    assert.equal(DEFAULT_RULESET.stocks, 3);
    assert.equal(DEFAULT_RULESET.matchType, "stock");
    assert.equal(DEFAULT_RULESET.stageId, "skyline-arena");
  });

  it("presets include required names", () => {
    const names = RULESET_PRESETS.map((p) => p.name);
    assert.ok(names.includes("Friendly 3 Stock"));
    assert.ok(names.includes("Quick 2 Minute"));
    assert.ok(names.includes("Stamina 100"));
    assert.ok(names.includes("Training Rules"));
    assert.ok(names.includes("Chaos Items"));
    assert.ok(names.includes("Competitive 1v1"));
  });

  it("gameConfigFromRuleset maps stage and stocks", () => {
    const fighters = [getDefaultCreatedFighter(0), getDefaultCreatedFighter(1)];
    const cfg = gameConfigFromRuleset(DEFAULT_RULESET, fighters, 42);
    assert.equal(cfg.stocks, 3);
    assert.equal(cfg.stageId, "skyline-arena");
    assert.equal(cfg.ruleset?.matchType, "stock");
    assert.equal(cfg.playerCount, effectivePlayerCount(DEFAULT_RULESET));
  });

  it("element mode helpers", () => {
    assert.equal(elementGameplayEnabled("on"), true);
    assert.equal(elementGameplayEnabled("visualOnly"), false);
    assert.equal(elementVisualsEnabled("off"), false);
    assert.equal(elementVisualsEnabled("visualOnly"), true);
  });

  it("timer frames conversion", () => {
    assert.equal(rulesetToMatchDurationFrames({ ...DEFAULT_RULESET, timerSeconds: 120 }), 120 * 60);
  });
});
