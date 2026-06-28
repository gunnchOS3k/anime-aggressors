import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  listStageLayoutIds,
  getStageLayout,
  stageHasLayout,
  listStages,
} from "@anime-aggressors/game-core";

const REQUIRED_STAGES = [
  "skyline-arena",
  "training-grid",
  "impact-platform",
  "flagline-center-clash",
  "flagline-lunar-outpost",
  "flagline-solar-outpost",
  "flagline-lunar-base",
  "flagline-solar-base",
];

describe("stage layouts", () => {
  it("all required stages have layout definitions", () => {
    const ids = listStageLayoutIds();
    for (const id of REQUIRED_STAGES) {
      assert.ok(ids.includes(id), `missing layout ${id}`);
      const layout = getStageLayout(id);
      assert.equal(layout.id, id);
      assert.ok(layout.platforms.length >= 1);
      assert.ok(layout.mainPlatformId);
    }
  });

  it("registered stages have matching layouts", () => {
    for (const id of REQUIRED_STAGES) {
      assert.equal(stageHasLayout(id), true, id);
      const stage = listStages().find((s) => s.id === id);
      assert.ok(stage, `missing stage def ${id}`);
    }
  });

  it("each layout has a main platform in platforms list", () => {
    for (const id of REQUIRED_STAGES) {
      const layout = getStageLayout(id);
      assert.ok(layout.platforms.some((p) => p.id === layout.mainPlatformId));
    }
  });
});
