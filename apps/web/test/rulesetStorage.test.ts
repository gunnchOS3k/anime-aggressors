import { describe, it, beforeEach } from "node:test";
import assert from "node:assert/strict";
import {
  listRulesets,
  saveRuleset,
  deleteRuleset,
  duplicateRuleset,
  getActiveRuleset,
  setActiveRulesetId,
  resetRulesetsToDefaults,
  createCustomRuleset,
} from "../src/storage/rulesetStorage.ts";
import { DEFAULT_RULESET } from "@anime-aggressors/game-core";

const store: Record<string, string> = {};

beforeEach(() => {
  for (const k of Object.keys(store)) delete store[k];
  (globalThis as { localStorage?: Storage }).localStorage = {
    getItem: (k) => store[k] ?? null,
    setItem: (k, v) => {
      store[k] = v;
    },
    removeItem: (k) => {
      delete store[k];
    },
    clear: () => {
      for (const k of Object.keys(store)) delete store[k];
    },
    key: () => null,
    length: 0,
  } as Storage;
  resetRulesetsToDefaults();
});

describe("rulesetStorage", () => {
  it("save/load/delete/duplicate ruleset", () => {
    const custom = createCustomRuleset("My Rules");
    const saved = saveRuleset({ ...custom, stocks: 1 });
    assert.ok(listRulesets().some((r) => r.id === saved.id));
    const dup = duplicateRuleset(saved.id);
    assert.ok(dup);
    assert.notEqual(dup!.id, saved.id);
    deleteRuleset(saved.id);
    assert.ok(!listRulesets().some((r) => r.id === saved.id));
  });

  it("set active ruleset", () => {
    setActiveRulesetId(DEFAULT_RULESET.id);
    assert.equal(getActiveRuleset().id, DEFAULT_RULESET.id);
  });
});
