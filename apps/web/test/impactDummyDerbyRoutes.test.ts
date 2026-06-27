import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { APP_ROUTES, hashToMode } from "../src/routes.ts";

describe("impact dummy derby routes", () => {
  it("routes include impact dummy derby and play", () => {
    assert.equal(APP_ROUTES.impactDummyDerby, "#/impact-dummy-derby");
    assert.equal(APP_ROUTES.play, "#/play");
    assert.equal(hashToMode("#/impact-dummy-derby"), "impact-dummy-derby");
    assert.equal(hashToMode("#/play"), "match");
  });
});
