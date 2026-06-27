import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  APP_ROUTES,
  allAppRoutesStartWithHash,
  assertHashRoute,
  navigateTo,
} from "../src/routes.ts";

describe("routing guard — no root paths", () => {
  it("APP_ROUTES.play is #/play", () => {
    assert.equal(APP_ROUTES.play, "#/play");
  });

  it("match setup entry uses hash route", () => {
    assert.equal(APP_ROUTES.matchSetupRules, "#/match-setup/rules");
  });

  it("no exported app route starts with /", () => {
    assert.equal(allAppRoutesStartWithHash(), true);
    for (const route of Object.values(APP_ROUTES)) {
      assert.ok(!route.startsWith("/"), `root path route found: ${route}`);
    }
  });

  it("route helper rejects /play", () => {
    assert.throws(() => assertHashRoute("/play"), /Invalid app route/);
    assert.throws(() => navigateTo("/play"), /Invalid app route/);
  });

  it("accepts hash routes", () => {
    assert.doesNotThrow(() => assertHashRoute("#/match-setup/rules"));
  });
});
