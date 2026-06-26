import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { APP_ROUTES, hashToMode } from "../src/routes.ts";

describe("custom game routes", () => {
  it("routes include custom-game and controls", () => {
    assert.equal(APP_ROUTES.customGame, "#/custom-game");
    assert.equal(hashToMode(APP_ROUTES.customGame), "custom-game");
    assert.equal(APP_ROUTES.controls, "#/controls");
    assert.equal(hashToMode(APP_ROUTES.controls), "controls");
    assert.equal(APP_ROUTES.controlsRemap, "#/controls/remap");
    assert.equal(hashToMode(APP_ROUTES.controlsRemap), "controls-remap");
    assert.equal(APP_ROUTES.rulesets, "#/rulesets");
    assert.equal(hashToMode(APP_ROUTES.rulesets), "rulesets");
  });
});
