import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  buildCreatedFighter,
  serializeCreatedFighter,
  deserializeCreatedFighter,
} from "../src/createdFighter.js";
import { createInitialGameState } from "../src/state.js";
import type { GameConfig } from "../src/types.js";

describe("created fighter match integration", () => {
  const fighter = buildCreatedFighter({ name: "Test Volt", size: "small", color: "yellow" });

  it("serializes and deserializes", () => {
    const json = serializeCreatedFighter(fighter);
    const back = deserializeCreatedFighter(json);
    assert.ok(back);
    assert.equal(back!.name, fighter.name);
    assert.equal(back!.size, "small");
    assert.equal(back!.color, "yellow");
  });

  it("can be used in match state", () => {
    const config: GameConfig = {
      playerCount: 2,
      stocks: 3,
      matchDurationFrames: 3600,
      stageId: "skyline-arena",
      characterIds: [`created:${fighter.id}`, "ember"],
      fighterProfiles: [fighter, buildCreatedFighter({ name: "P2", size: "large", color: "violet" })],
      seed: 42,
    };
    const state = createInitialGameState(config);
    assert.equal(state.players[0].fighterName, "Test Volt");
    assert.equal(state.players[0].fighterSize, "small");
    assert.equal(state.players[0].elementEffect, "shock");
    assert.equal(state.players[1].fighterSize, "large");
  });
});
