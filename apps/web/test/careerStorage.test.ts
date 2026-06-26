import { describe, it, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { resetCareerDbForTests } from "../src/storage/careerDb.ts";
import {
  getCareerProfile,
  saveCareerProfile,
  recordMatchToCareer,
} from "../src/storage/careerStorage.ts";
import {
  buildMatchRecordFromEvents,
  createInitialGameState,
  gameConfigFromRuleset,
  DEFAULT_RULESET,
  getDefaultCreatedFighter,
} from "@anime-aggressors/game-core";

const store: Record<string, string> = {};

beforeEach(async () => {
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
  await resetCareerDbForTests();
});

describe("careerStorage", () => {
  it("save/load career profile", () => {
    const profile = getCareerProfile();
    assert.ok(profile.id);
    const updated = saveCareerProfile({ ...profile, displayName: "Tester" });
    assert.equal(getCareerProfile().displayName, "Tester");
    assert.equal(updated.displayName, "Tester");
  });

  it("match record updates career via storage", async () => {
    const fighter = getDefaultCreatedFighter(0);
    const config = gameConfigFromRuleset(DEFAULT_RULESET, [fighter, fighter], 3);
    const initial = createInitialGameState(config);
    const final = createInitialGameState(config);
    final.frame = 600;
    final.winnerId = 0;

    const match = buildMatchRecordFromEvents({
      initialState: initial,
      finalState: final,
      events: [
        { type: "matchStarted", frame: 0, mode: "playMatch" },
        { type: "ko", frame: 100, attackerPlayerId: 0, victimPlayerId: 1 },
        { type: "matchEnded", frame: 600, winnerPlayerId: 0 },
      ],
    });

    const result = await recordMatchToCareer(match, 0);
    assert.equal(result.career.totalMatches, 1);
    assert.equal(result.career.totalKOs, 1);
  });
});
