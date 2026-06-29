import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { createInitialGameState, gameConfigFromRuleset, DEFAULT_RULESET, getDefaultCreatedFighter } from "@anime-aggressors/game-core";
import { computeCameraFrameTarget, computeZoomFactor, CAMERA_DEFAULTS } from "../src/renderer-three/camera/CameraBounds.ts";

const config = gameConfigFromRuleset(DEFAULT_RULESET, [getDefaultCreatedFighter(0), getDefaultCreatedFighter(1)], 1);

describe("platform fighter camera zoom", () => {
  it("max zoom is capped at 1.18 for readability", () => {
    assert.equal(CAMERA_DEFAULTS.maxZoom, 1.18);
    assert.ok(CAMERA_DEFAULTS.minZoom < CAMERA_DEFAULTS.defaultZoom);
  });

  it("zooms out when fighters separate", () => {
    const state = createInitialGameState(config);
    state.players[0].x = 300 * 256;
    state.players[1].x = 1800 * 256;
    const far = computeZoomFactor(computeCameraFrameTarget(state), 16 / 9);

    state.players[0].x = 700 * 256;
    state.players[1].x = 800 * 256;
    const close = computeZoomFactor(computeCameraFrameTarget(state), 16 / 9);
    assert.ok(far < close);
  });

  it("never exceeds max zoom during normal framing", () => {
    const state = createInitialGameState(config);
    const z = computeZoomFactor(computeCameraFrameTarget(state), 16 / 9);
    assert.ok(z <= CAMERA_DEFAULTS.maxZoom);
  });
});
