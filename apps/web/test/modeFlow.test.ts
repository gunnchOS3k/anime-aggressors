import { describe, it, beforeEach } from "node:test";
import assert from "node:assert/strict";

const storage = new Map<string, string>();
(globalThis as { localStorage?: Storage }).localStorage = {
  getItem: (k) => storage.get(k) ?? null,
  setItem: (k, v) => storage.set(k, v),
  removeItem: (k) => storage.delete(k),
  clear: () => storage.clear(),
  key: () => null,
  length: 0,
};

const { resolveModeEntry, resolveBattleRoute } = await import("../src/navigation/modeFlow.ts");
const { APP_ROUTES } = await import("../src/routes.ts");
const { clearMatchSetup, createDefaultMatchSetup, saveMatchSetup } = await import(
  "../src/match/matchSetupSession.ts"
);

beforeEach(() => {
  storage.clear();
  clearMatchSetup();
});

describe("mode flow", () => {
  it("start match without rules routes to rules select", () => {
    saveMatchSetup({ ...createDefaultMatchSetup(), rulesetId: undefined, ruleset: undefined });
    const r = resolveModeEntry("startMatch");
    assert.equal(r.route, APP_ROUTES.matchSetupRules);
    assert.equal(r.mode, "match-setup-rules");
  });

  it("start match without stage routes to map select", () => {
    const base = createDefaultMatchSetup();
    saveMatchSetup({ ...base, stageId: undefined, stageName: undefined });
    const r = resolveModeEntry("startMatch");
    assert.equal(r.route, APP_ROUTES.matchSetupStage);
  });

  it("battle route redirects when fighters missing", async () => {
    const { guardBattleEntry } = await import("../src/navigation/modeEntryGuards.ts");
    const base = createDefaultMatchSetup();
    const guard = guardBattleEntry({ ...base, fighters: [] });
    assert.equal(guard.ok, false);
    assert.equal(guard.redirectMode, "match-setup-fighters");
  });

  it("derby without fighter routes to create fighter", () => {
    const r = resolveModeEntry("impactDummyDerby", false);
    assert.equal(r.mode, "create-fighter");
  });
});
