import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { createInitialGameState, gameConfigFromRuleset, DEFAULT_RULESET, getDefaultCreatedFighter } from "@anime-aggressors/game-core";
import { computeCameraFrameTarget, computeZoomFactor, CAMERA_DEFAULTS } from "../src/renderer-three/camera/CameraBounds.ts";

const config = gameConfigFromRuleset(DEFAULT_RULESET, [getDefaultCreatedFighter(0), getDefaultCreatedFighter(1)], 1);

describe("platform fighter camera", () => {
  it("zooms out as fighters separate", () => {
    const state = createInitialGameState(config);
    state.players[0].x = 400 * 256;
    state.players[1].x = 1400 * 256;
    const far = computeZoomFactor(computeCameraFrameTarget(state), 16 / 9);

    state.players[0].x = 700 * 256;
    state.players[1].x = 800 * 256;
    const close = computeZoomFactor(computeCameraFrameTarget(state), 16 / 9);

    assert.ok(far < close, "farther fighters should yield lower zoom factor (more zoomed out)");
  });

  it("respects min/max zoom", () => {
    const state = createInitialGameState(config);
    state.players[0].x = 100 * 256;
    state.players[1].x = 1900 * 256;
    const z = computeZoomFactor(computeCameraFrameTarget(state), 16 / 9);
    assert.ok(z >= CAMERA_DEFAULTS.minZoom);
    assert.ok(z <= CAMERA_DEFAULTS.maxZoom);
  });

  it("frames both fighters in target bounds", () => {
    const state = createInitialGameState(config);
    const target = computeCameraFrameTarget(state);
    assert.ok(target.requiredWidth > 0);
    assert.ok(target.requiredHeight > 0);
  });
});
