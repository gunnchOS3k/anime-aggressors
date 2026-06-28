import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("battle route render wiring", () => {
  it("App uses createBattleScene for battle boot", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/game/App.ts"), "utf8");
    assert.match(src, /createBattleScene/);
    assert.match(src, /RendererDiagnostics/);
    assert.match(src, /battle-screen/);
  });

  it("battle route launches match with skipSelect", () => {
    const main = fs.readFileSync(path.join(webRoot, "src/main.ts"), "utf8");
    assert.match(main, /#\/battle|battle/);
    assert.match(main, /skipSelect:\s*true/);
  });

  it("styles guarantee nonzero battle canvas shell height", () => {
    const css = fs.readFileSync(path.join(webRoot, "src/styles.css"), "utf8");
    assert.match(css, /\.battle-screen/);
    assert.match(css, /min-height:\s*520px/);
    assert.match(css, /\.three-battle-canvas/);
  });

  it("createBattleScene module exports boot contract", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/renderer-three/createBattleScene.ts"), "utf8");
    assert.match(src, /BattleSceneBootResult/);
    assert.match(src, /stageLoaded/);
    assert.match(src, /fightersLoaded/);
  });
});
