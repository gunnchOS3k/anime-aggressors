import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  buildStageModel,
  listRenderableStageIds,
} from "../src/renderer-three/stages/StageModelFactory.ts";

describe("stage factory", () => {
  it("lists required stages", () => {
    const ids = listRenderableStageIds();
    for (const id of [
      "skyline-arena",
      "training-grid",
      "impact-platform",
      "flagline-center-clash",
      "flagline-lunar-outpost",
      "flagline-solar-outpost",
      "flagline-lunar-base",
      "flagline-solar-base",
    ]) {
      assert.ok(ids.includes(id), `missing stage ${id}`);
    }
  });

  it("builds renderable scene groups for each stage", () => {
    for (const id of listRenderableStageIds()) {
      const built = buildStageModel(id);
      assert.ok(built.group.children.length > 0, `${id} has no children`);
      assert.equal(built.stageId, id);
      assert.ok(built.name.length > 0);
    }
  });

  it("falls back to training grid for unknown stage id", () => {
    const built = buildStageModel("unknown-stage");
    assert.equal(built.stageId, "training-grid");
    assert.ok(built.objectCount > 0);
  });
});
