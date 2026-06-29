import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { buildStagePreviewScene } from "../src/renderer-three/stage-preview/StagePreviewScene.ts";

const STAGE_IDS = [
  "skyline-arena",
  "training-grid",
  "impact-platform",
  "flagline-center-clash",
  "flagline-lunar-outpost",
  "flagline-solar-outpost",
  "flagline-lunar-base",
  "flagline-solar-base",
] as const;

describe("stage preview renderer", () => {
  it("buildStagePreviewScene returns visible geometry for each stage", () => {
    for (const id of STAGE_IDS) {
      const built = buildStagePreviewScene(id);
      assert.ok(built.objectCount > 3, `${id} should have meshes`);
    }
  });

  it("StagePreviewRenderer module exposes hasVisibleGeometry helper", async () => {
    const mod = await import("../src/renderer-three/stage-preview/StagePreviewRenderer.ts");
    assert.equal(typeof mod.createStagePreviewRenderer, "function");
    const built = buildStagePreviewScene("skyline-arena");
    assert.ok(built.objectCount > 3);
  });
});
