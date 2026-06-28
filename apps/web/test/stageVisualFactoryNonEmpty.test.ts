import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  buildStageModel,
  buildFallbackStageModel,
  listRenderableStageIds,
} from "../src/renderer-three/stages/StageModelFactory.ts";

describe("stage visual factory non-empty", () => {
  it("every selectable stage returns meshes", () => {
    for (const id of listRenderableStageIds()) {
      const built = buildStageModel(id);
      assert.ok(built.objectCount > 0, `${id} objectCount`);
      assert.ok(built.group.children.length > 0, `${id} children`);
    }
  });

  it("unknown stage uses fallback training grid", () => {
    const built = buildStageModel("does-not-exist");
    assert.ok(built.objectCount > 0);
    assert.equal(built.stageId, "training-grid");
  });

  it("explicit fallback stage is non-empty", () => {
    const built = buildFallbackStageModel();
    assert.ok(built.objectCount > 0);
    assert.match(built.name, /Training|Grid/i);
  });
});
