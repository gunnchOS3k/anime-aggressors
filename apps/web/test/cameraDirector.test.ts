import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { createInitialGameState, type GameConfig } from "@anime-aggressors/game-core";
import { computeCameraBounds } from "../src/renderer-three/cameraBounds.ts";

const config: GameConfig = {
  playerCount: 2,
  stocks: 3,
  matchDurationFrames: 180 * 60,
  stageId: "skyline-arena",
  characterIds: ["ember", "tide"],
  seed: 5,
};

describe("camera bounds", () => {
  it("computeCameraBounds returns stable padding around players", () => {
    const state = createInitialGameState(config);
    const b = computeCameraBounds(state);
    assert.ok(b.maxX > b.minX);
    assert.ok(b.maxY > b.minY);
    assert.ok(b.minX < state.players[0].x / 256);
    assert.ok(b.maxX > state.players[1].x / 256);
  });
});
