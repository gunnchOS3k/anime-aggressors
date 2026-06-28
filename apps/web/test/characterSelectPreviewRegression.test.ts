import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("character select preview regression", () => {
  it("uses createPreviewFighterModel not battle scale in preview renderer", () => {
    const src = fs.readFileSync(
      path.join(webRoot, "src/renderer-three/preview/CharacterPreviewRenderer.ts"),
      "utf8",
    );
    assert.match(src, /createPreviewFighterModel/);
    assert.doesNotMatch(src, /createFighterModel/);
  });

  it("character select rebinds preview canvas after DOM refresh", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/screens/CharacterSelectScreen.ts"), "utf8");
    assert.match(src, /getCanvas\(\) !== canvas/);
    assert.match(src, /querySelector\("#cs-preview-canvas"\)/);
  });

  it("preview panel CSS guarantees minimum canvas height", () => {
    const css = fs.readFileSync(path.join(webRoot, "src/styles.css"), "utf8");
    assert.match(css, /\.character-preview-panel/);
    assert.match(css, /min-height:\s*320px/);
    assert.match(css, /\.character-preview-canvas/);
    assert.match(css, /min-height:\s*300px/);
  });

  it("fighter preview panel includes character-preview classes", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/ui/FighterPreviewPanel.ts"), "utf8");
    assert.match(src, /character-preview-panel/);
    assert.match(src, /character-preview-canvas/);
  });
});
