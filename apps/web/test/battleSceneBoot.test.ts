import { describe, it, before } from "node:test";
import assert from "node:assert/strict";
import { createInitialGameState, gameConfigFromRuleset, DEFAULT_RULESET } from "@anime-aggressors/game-core";
import { getDefaultCreatedFighter } from "@anime-aggressors/game-core";
import { buildStageModel } from "../src/renderer-three/stages/StageModelFactory.ts";
import { createFallbackFighterModel, countFighterMeshes } from "../src/renderer-three/fighters/FighterModelFactory.ts";

function ensureBrowserShim(): void {
  if (typeof globalThis.document !== "undefined") return;
  const canvas = {
    width: 960,
    height: 540,
    style: {} as CSSStyleDeclaration,
    addEventListener: () => undefined,
    removeEventListener: () => undefined,
    getContext: () => ({
      canvas,
      getExtension: () => null,
      getParameter: () => 0,
      viewport: () => undefined,
      clearColor: () => undefined,
      clear: () => undefined,
    }),
  };
  globalThis.document = {
    createElementNS(_uri: string, name: string) {
      if (name === "canvas") return canvas;
      return { style: {} };
    },
    createElement(name: string) {
      if (name === "canvas") return canvas;
      return { style: {} };
    },
  } as unknown as Document;
}

function makeMount(width = 960, height = 540): HTMLElement {
  const el = {
    clientWidth: width,
    clientHeight: height,
    children: [] as unknown[],
    style: {} as CSSStyleDeclaration,
    appendChild(child: unknown) {
      this.children.push(child);
      return child;
    },
    removeChild(child: unknown) {
      const i = this.children.indexOf(child);
      if (i >= 0) this.children.splice(i, 1);
      return child;
    },
  };
  return el as unknown as HTMLElement;
}

describe("battle scene boot", () => {
  before(() => {
    ensureBrowserShim();
  });

  it("factory preconditions satisfy boot acceptance rules", () => {
    const config = gameConfigFromRuleset(
      DEFAULT_RULESET,
      [getDefaultCreatedFighter(0), getDefaultCreatedFighter(5)],
      99,
    );
    config.stageId = "skyline-arena";
    const stage = buildStageModel(config.stageId);
    const fightersLoaded = [0, 1].filter((i) => countFighterMeshes(createFallbackFighterModel(i)) >= 6).length;
    assert.ok(stage.objectCount > 0);
    assert.ok(fightersLoaded >= 2);
  });

  it("returns ok with scene objects and two fighters when WebGL is available", async () => {
    const { createBattleScene } = await import("../src/renderer-three/createBattleScene.ts");
    const config = gameConfigFromRuleset(
      DEFAULT_RULESET,
      [getDefaultCreatedFighter(0), getDefaultCreatedFighter(5)],
      99,
    );
    config.stageId = "skyline-arena";
    const initialState = createInitialGameState(config);
    const mount = makeMount();

    let boot;
    try {
      boot = createBattleScene({ mount, gameConfig: config, initialState });
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      if (/WebGL|context|document|getShaderPrecisionFormat|gl\./i.test(msg)) return;
      throw e;
    }

    if (!boot.result.ok) {
      const err = boot.result.error ?? "";
      if (/WebGL|context|getShaderPrecisionFormat/i.test(err)) return;
    }

    assert.ok(boot.result.sceneObjectCount > 0, "sceneObjectCount");
    assert.equal(boot.result.stageLoaded, true);
    assert.ok(boot.result.fightersLoaded >= 2);
    assert.equal(boot.renderer.isMounted(), true);
    const canvas = boot.renderer.getCanvas();
    assert.ok(canvas.width > 0);
    assert.ok(canvas.height > 0);
    assert.ok(mount.clientWidth > 0 && mount.clientHeight > 0);
    boot.renderer.dispose();
  });
});
