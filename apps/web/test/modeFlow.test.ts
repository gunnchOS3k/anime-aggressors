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
const { clearDerbySetup } = await import("../src/modes/impactDummyDerbySetup.ts");

beforeEach(() => {
  storage.clear();
  clearMatchSetup();
  clearDerbySetup();
});

describe("mode flow", () => {
  it("start match without fighters routes to fighter select", () => {
    const base = createDefaultMatchSetup();
    saveMatchSetup({
      ...base,
      fighters: [
        { playerId: 0 },
        { playerId: 1 },
      ],
    });
    const r = resolveModeEntry("startMatch");
    assert.equal(r.route, APP_ROUTES.fighterSelect);
    assert.equal(r.mode, "fighter-select");
  });

  it("start match without stage routes to stage select", () => {
    const base = createDefaultMatchSetup();
    saveMatchSetup({ ...base, stageId: undefined, stageName: undefined });
    const r = resolveModeEntry("startMatch");
    assert.equal(r.route, APP_ROUTES.stageSelect);
    assert.equal(r.mode, "stage-select");
  });

  it("battle route redirects when fighters missing", async () => {
    const { guardBattleEntry } = await import("../src/navigation/modeEntryGuards.ts");
    const base = createDefaultMatchSetup();
    const guard = guardBattleEntry({ ...base, fighters: [] });
    assert.equal(guard.ok, false);
    assert.equal(guard.redirectMode, "fighter-select");
  });

  it("derby without fighter routes to fighter select", () => {
    const r = resolveModeEntry("impactDummyDerby");
    assert.equal(r.mode, "impact-dummy-derby-fighter-select");
    assert.equal(r.route, APP_ROUTES.impactDummyDerbyFighterSelect);
  });
});
