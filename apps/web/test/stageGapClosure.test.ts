import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { listRenderableStageIds } from "../src/renderer-three/stages/StageModelFactory.ts";
import { getStageVisualConfig } from "../src/renderer-three/stages/stageVisualConfigs.ts";
import { measureStagePlatformDepth } from "../src/renderer-three/stages/StageModelFactory.ts";
import { buildStageModel } from "../src/renderer-three/stages/StageModelFactory.ts";

describe("stage gap closure", () => {
  it("each stage has title, lighting config, and thickness", () => {
    for (const id of listRenderableStageIds()) {
      const visual = getStageVisualConfig(id);
      assert.ok(visual.title.length > 0, id);
      assert.ok(visual.accentHex.length > 0, id);
      assert.ok(visual.ambientHex.length > 0, id);
      assert.equal(visual.competitive, true, id);
      const built = buildStageModel(id);
      assert.ok(measureStagePlatformDepth(built.group) > 0, id);
      assert.ok(built.objectCount >= 3, id);
    }
  });
});
