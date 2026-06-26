import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  buildMatchRecordFromEvents,
  createInitialGameState,
  gameConfigFromRuleset,
  DEFAULT_RULESET,
  getDefaultCreatedFighter,
  type StatEvent,
} from "../src/index.js";

describe("match record", () => {
  it("builds scoreboard from events", () => {
    const fighter = getDefaultCreatedFighter(0);
    const config = gameConfigFromRuleset(DEFAULT_RULESET, [fighter, fighter], 99);
    const initial = createInitialGameState(config);
    const final = createInitialGameState(config);
    final.frame = 1800;
    final.winnerId = 0;
    final.phase = "results";

    const events: StatEvent[] = [
      { type: "matchStarted", frame: 0, mode: "playMatch" },
      { type: "ko", frame: 300, attackerPlayerId: 0, victimPlayerId: 1 },
      { type: "fall", frame: 300, victimPlayerId: 1 },
      { type: "damage", frame: 250, attackerPlayerId: 0, victimPlayerId: 1, amount: 40 },
      { type: "matchEnded", frame: 1800, winnerPlayerId: 0 },
    ];

    const record = buildMatchRecordFromEvents({ initialState: initial, finalState: final, events });

    assert.equal(record.mode, "playMatch");
    assert.equal(record.durationFrames, 1800);
    assert.equal(record.winnerPlayerId, 0);
    assert.equal(record.players[0].kos, 1);
    assert.equal(record.players[1].falls, 2);
    assert.equal(record.players[0].damageDealt, 40);
    assert.equal(record.players[1].damageTaken, 40);
    assert.equal(record.scoreboard[0].playerId, 0);
  });

  it("KOs and falls counted correctly", () => {
    const fighter = getDefaultCreatedFighter(0);
    const config = gameConfigFromRuleset(DEFAULT_RULESET, [fighter, fighter], 5);
    const initial = createInitialGameState(config);
    const final = createInitialGameState(config);
    final.frame = 900;

    const events: StatEvent[] = [
      { type: "matchStarted", frame: 0, mode: "customGame" },
      { type: "ko", frame: 100, attackerPlayerId: 1, victimPlayerId: 0 },
      { type: "ko", frame: 200, attackerPlayerId: 0, victimPlayerId: 1 },
      { type: "matchEnded", frame: 900, winnerPlayerId: 0 },
    ];

    const record = buildMatchRecordFromEvents({ initialState: initial, finalState: final, events });
    assert.equal(record.players[0].kos, 1);
    assert.equal(record.players[0].falls, 1);
    assert.equal(record.players[1].kos, 1);
    assert.equal(record.players[1].falls, 1);
  });
});
