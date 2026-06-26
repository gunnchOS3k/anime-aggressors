import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { createInitialGameState, type GameConfig } from "@anime-aggressors/game-core";
import {
  fpToWorld,
  mapGameStateReadOnly,
  mapPlayerToRenderable,
} from "../src/renderer-three/RenderTypes.ts";

const config: GameConfig = {
  playerCount: 2,
  stocks: 3,
  matchDurationFrames: 180 * 60,
  stageId: "skyline-arena",
  characterIds: ["ember", "tide"],
  seed: 3,
};

describe("renderer mapping", () => {
  it("fpToWorld converts fixed point", () => {
    assert.equal(fpToWorld(256), 1);
    assert.equal(fpToWorld(512), 2);
  });

  it("mapPlayerToRenderable does not include velocity authority", () => {
    const state = createInitialGameState(config);
    const mapped = mapPlayerToRenderable(state.players[0]);
    assert.equal(mapped.id, 0);
    assert.ok(typeof mapped.x === "number");
    assert.ok(!("vx" in mapped));
  });

  it("mapGameStateReadOnly does not mutate GameState", () => {
    const state = createInitialGameState(config);
    const snapshot = JSON.stringify(state);
    mapGameStateReadOnly(state);
    assert.equal(JSON.stringify(state), snapshot);
  });
});
