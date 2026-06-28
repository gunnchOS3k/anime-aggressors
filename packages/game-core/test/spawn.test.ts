import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getStage, defaultBattleSpawns, validateSpawnPoints, spawnDisplayX } from "../src/index.js";
import { FLOOR_Y, STAGE_WIDTH } from "../src/constants.js";

describe("spawn helpers", () => {
  it("defaultBattleSpawns places P1 left and P2 right above floor", () => {
    const spawns = defaultBattleSpawns();
    assert.equal(spawns.length, 2);
    assert.ok(spawns[0]!.x < spawns[1]!.x);
    assert.ok(spawns[0]!.y < FLOOR_Y);
    assert.ok(spawns[1]!.y < FLOOR_Y);
  });

  it("spawnDisplayX returns stage thirds", () => {
    assert.equal(spawnDisplayX(0), STAGE_WIDTH / 3);
    assert.equal(spawnDisplayX(1), (STAGE_WIDTH * 2) / 3);
  });

  it("validateSpawnPoints passes for default skyline arena", () => {
    const stage = getStage("skyline-arena");
    const warnings = validateSpawnPoints(stage);
    assert.deepEqual(warnings, []);
  });
});
