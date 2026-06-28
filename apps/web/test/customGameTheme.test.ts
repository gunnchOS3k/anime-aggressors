import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("custom game theme", () => {
  it("uses setup shell and rules editor panel", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/screens/CustomGameScreen.ts"), "utf8");
    assert.match(src, /renderSetupFlowShell/);
    assert.match(src, /rules-editor-panel/);
    assert.match(src, /primary-game-cta|Choose Fighters/);
  });
});
