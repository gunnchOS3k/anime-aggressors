import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { ReplayRecorder } from "../src/replay/ReplayRecorder.ts";
import {
  createInitialGameState,
  gameConfigFromRuleset,
  DEFAULT_RULESET,
  getDefaultCreatedFighter,
  verifyReplayRecord,
  simulateFrame,
} from "@anime-aggressors/game-core";

describe("ReplayRecorder", () => {
  it("records inputs and produces verifiable replay", () => {
    const fighter = getDefaultCreatedFighter(0);
    const config = gameConfigFromRuleset(DEFAULT_RULESET, [fighter, fighter], 77);
    const initial = createInitialGameState(config);
    const recorder = new ReplayRecorder({
      gameVersion: "0.1.0",
      mode: "playMatch",
      ruleset: DEFAULT_RULESET,
    });
    recorder.start(initial);

    for (let f = 0; f < 20; f++) {
      recorder.recordFrame(f, [
        {
          frame: f,
          playerId: 0,
          left: false,
          right: f % 2 === 0,
          up: false,
          down: false,
          jump: false,
          attack: false,
          special: false,
          shield: false,
          dodge: false,
          grab: false,
        },
        {
          frame: f,
          playerId: 1,
          left: false,
          right: false,
          up: false,
          down: false,
          jump: false,
          attack: false,
          special: false,
          shield: false,
          dodge: false,
          grab: false,
        },
      ]);
    }

    let state = initial;
    for (const entry of recorder.getInputLog()) {
      state = simulateFrame(state, entry.inputs);
    }

    const replay = recorder.finalize("match-1", state);
    assert.ok(replay);
    const verification = verifyReplayRecord(replay!);
    assert.equal(verification.valid, true);
  });
});
