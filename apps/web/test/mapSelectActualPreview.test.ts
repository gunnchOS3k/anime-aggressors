import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { renderStagePreviewHeroPanel } from "../src/ui/stage/StagePreviewCanvas.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("map select actual preview", () => {
  it("stage preview panel includes live canvas not only minimap", () => {
    const html = renderStagePreviewHeroPanel("skyline-arena");
    assert.match(html, /stage-preview-canvas/);
    assert.match(html, /stage-minimap/);
    assert.match(html, /SKYLINE ARENA/i);
  });

  it("MatchSetupStageScreen wires StagePreviewRenderer", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/screens/MatchSetupStageScreen.ts"), "utf8");
    assert.match(src, /createStagePreviewRenderer/);
    assert.match(src, /renderStagePreviewHeroPanel/);
    assert.match(src, /stage-preview-canvas/);
  });

  it("impact platform preview mentions runway vibe", () => {
    const html = renderStagePreviewHeroPanel("impact-platform");
    assert.match(html, /IMPACT PLATFORM/i);
    assert.match(html, /stage-preview-canvas/);
  });
});
