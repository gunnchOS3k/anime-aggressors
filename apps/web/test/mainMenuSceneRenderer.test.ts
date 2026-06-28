import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createMenuFighterShowcase } from "../src/renderer-three/menu/MenuFighterShowcase.ts";
import { createMenuStageDiorama } from "../src/renderer-three/menu/MenuStageDiorama.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("main menu scene renderer", () => {
  it("MainMenuSceneRenderer module wires diorama, aura, and fighters", () => {
    const src = fs.readFileSync(
      path.join(webRoot, "src/renderer-three/menu/MainMenuSceneRenderer.ts"),
      "utf8",
    );
    assert.match(src, /createMenuStageDiorama/);
    assert.match(src, /createMenuAuraBackdrop/);
    assert.match(src, /createMenuFighterShowcase/);
    assert.match(src, /hasFighterShowcase/);
  });

  it("includes at least one fighter showcase model", () => {
    const showcase = createMenuFighterShowcase();
    assert.ok(showcase.fighterCount >= 1);
    assert.ok(showcase.meshCount >= 6);
  });

  it("stage diorama has platform geometry", () => {
    const diorama = createMenuStageDiorama();
    let meshCount = 0;
    diorama.group.traverse((o) => {
      if ("isMesh" in o && (o as { isMesh?: boolean }).isMesh) meshCount += 1;
    });
    assert.ok(meshCount >= 3);
  });
});
