import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { listStages } from "@anime-aggressors/game-core";
import { renderStagePreviewHero, renderStageSelectGrid } from "../src/ui/stage/StageSelectGrid.ts";

describe("stage select theme", () => {
  it("stage preview hero shows name and vibe", () => {
    const html = renderStagePreviewHero("skyline-arena");
    assert.match(html, /SKYLINE ARENA/);
    assert.match(html, /stage-preview-hero/);
    assert.match(html, /Modes/);
    assert.match(html, /Hazards/);
  });

  it("stage grid renders thumbnails", () => {
    const stages = listStages().filter((s) => s.id === "skyline-arena" || s.id === "training-grid");
    const html = renderStageSelectGrid(stages, "skyline-arena");
    assert.match(html, /stage-select-thumb/);
    assert.match(html, /selected/);
  });
});
