import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  buildStageModel,
  buildFallbackStageModel,
  listRenderableStageIds,
  measureStagePlatformDepth,
} from "../src/renderer-three/stages/StageModelFactory.ts";
import { STAGE_PLATFORM_DEPTH } from "../src/renderer-three/RenderTypes.ts";

describe("stage model depth", () => {
  it("platforms have minimum thickness for 2.5D presentation", () => {
    for (const id of listRenderableStageIds()) {
      const built = buildStageModel(id);
      const depth = measureStagePlatformDepth(built.group);
      assert.ok(depth >= STAGE_PLATFORM_DEPTH * 0.5, `${id} depth ${depth}`);
      assert.ok(built.objectCount >= 3, `${id} object count`);
    }
  });

  it("fallback stage has thick platforms", () => {
    const built = buildFallbackStageModel();
    assert.ok(measureStagePlatformDepth(built.group) >= STAGE_PLATFORM_DEPTH * 0.5);
  });
});
