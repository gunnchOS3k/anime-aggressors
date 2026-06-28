import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { renderStageGrid } from "../src/ui/StageGrid.ts";
import { renderStagePreviewPanel, layoutPlatformIds } from "../src/ui/StagePreviewPanel.ts";
import { listStages } from "@anime-aggressors/game-core";

describe("stage select preview", () => {
  it("renders stage grid with selection state", () => {
    const stages = listStages().filter((s) => s.id === "skyline-arena" || s.id === "training-grid");
    const html = renderStageGrid({ stages, selectedId: "skyline-arena" });
    assert.match(html, /stage-select-grid/);
    assert.match(html, /selected/);
    assert.match(html, /Skyline Arena/);
  });

  it("renders preview panel with mini-map", () => {
    const html = renderStagePreviewPanel({ stageId: "skyline-arena" });
    assert.match(html, /stage-preview-panel/);
    assert.match(html, /stage-minimap/);
    assert.match(html, /Neon rooftop/);
  });

  it("mini-map platform ids match layout", () => {
    const ids = layoutPlatformIds("skyline-arena");
    assert.ok(ids.includes("main"));
    assert.ok(ids.length >= 3);
  });
});
