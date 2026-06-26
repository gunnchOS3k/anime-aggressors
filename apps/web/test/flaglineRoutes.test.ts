import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { APP_ROUTES, hashToMode } from "../src/routes.ts";

describe("flagline routes", () => {
  it("routes exist", () => {
    assert.equal(APP_ROUTES.flaglineClash, "#/flagline-clash");
    assert.equal(hashToMode(APP_ROUTES.flaglineClash), "flagline-clash");
    assert.equal(APP_ROUTES.flaglineSetup, "#/flagline-setup");
    assert.equal(hashToMode(APP_ROUTES.flaglineSetup), "flagline-setup");
    assert.equal(APP_ROUTES.flaglineTeams, "#/flagline-teams");
    assert.equal(hashToMode(APP_ROUTES.flaglineTeams), "flagline-teams");
  });
});
