import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("flagline clash visuals", () => {
  it("flagline view uses stage theme and flag core", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/modes/flaglineClashView.ts"), "utf8");
    assert.match(src, /FlaglineStageView/);
    assert.match(src, /FlagCoreView/);
  });

  it("stage factory includes flagline rooms", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/renderer-three/stages/StageModelFactory.ts"), "utf8");
    assert.match(src, /flagline-center-clash/);
    assert.match(src, /flagline-lunar-base/);
    assert.match(src, /flagline-solar-base/);
  });
});
