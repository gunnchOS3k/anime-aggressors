import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { createInitialGameState, gameConfigFromRuleset, DEFAULT_RULESET } from "@anime-aggressors/game-core";
import { getAllDefaultCreatedFighters } from "@anime-aggressors/game-core";
import { buildStageModel, buildFallbackStageModel } from "../src/renderer-three/stages/StageModelFactory.ts";
import { createFighterModel, createFallbackFighterModel, countFighterMeshes } from "../src/renderer-three/fighters/FighterModelFactory.ts";
import { resolveFighterAppearance } from "../src/renderer-three/fighters/FighterAppearance.ts";

describe("battle renderer fallbacks", () => {
  it("ember vs orion creates at least two fighter models", () => {
    const ember = getAllDefaultCreatedFighters().find((f) => f.id === "ember-vale")!;
    const orion = getAllDefaultCreatedFighters().find((f) => f.id === "orion-vell")!;
    const config = gameConfigFromRuleset(DEFAULT_RULESET, [ember, orion], 42);
    config.stageId = "skyline-arena";
    const state = createInitialGameState(config);
    assert.equal(state.players.length, 2);

    const p0 = createFighterModel(resolveFighterAppearance(ember));
    const p1 = createFighterModel(resolveFighterAppearance(orion));
    assert.ok(countFighterMeshes(p0) >= 6);
    assert.ok(countFighterMeshes(p1) >= 6);
  });

  it("fallback stage and fighter never return empty", () => {
    assert.ok(buildFallbackStageModel().objectCount > 0);
    assert.ok(countFighterMeshes(createFallbackFighterModel(1)) > 0);
  });

  it("broken stage id still yields geometry via factory", () => {
    assert.ok(buildStageModel("broken-stage-xyz").objectCount > 0);
  });

  it("custom appearance still builds meshes", () => {
    const fighter = getAllDefaultCreatedFighters()[0]!;
    const appearance = resolveFighterAppearance(fighter);
    assert.ok(countFighterMeshes(createFighterModel(appearance)) > 0);
  });
});
