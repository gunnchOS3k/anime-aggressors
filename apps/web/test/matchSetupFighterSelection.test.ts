import { describe, it, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { getAllDefaultCreatedFighters } from "@anime-aggressors/game-core";

const storage = new Map<string, string>();

(globalThis as { localStorage?: Storage }).localStorage = {
  getItem: (k) => storage.get(k) ?? null,
  setItem: (k, v) => storage.set(k, v),
  removeItem: (k) => storage.delete(k),
  clear: () => storage.clear(),
  key: () => null,
  length: 0,
};

const { saveMatchSetup, loadMatchSetup, clearMatchSetup, createDefaultMatchSetup } = await import(
  "../src/match/matchSetupSession.ts"
);

beforeEach(() => {
  storage.clear();
  clearMatchSetup();
});

describe("match setup fighter selection", () => {
  it("persists selected default fighters into session", () => {
    const roster = getAllDefaultCreatedFighters();
    const setup = createDefaultMatchSetup();
    saveMatchSetup({
      ...setup,
      fighters: [
        { playerId: 0, fighterId: roster[0]!.id, fighter: roster[0]! },
        { playerId: 1, fighterId: roster[4]!.id, fighter: roster[4]! },
      ],
    });
    const loaded = loadMatchSetup();
    assert.equal(loaded.fighters[0]?.fighter?.name, "Ember Vale");
    assert.equal(loaded.fighters[1]?.fighter?.name, "Nix Calder");
  });

  it("default setup uses roster fighters", () => {
    const setup = createDefaultMatchSetup();
    assert.equal(setup.fighters[0]?.fighter?.id, "ember-vale");
    assert.equal(setup.fighters[1]?.fighter?.id, "rook-ironside");
  });
});
