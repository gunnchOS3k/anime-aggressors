import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  APP_ROUTES,
  hashToMode,
  modeToHash,
  assertPagesBaseInHtml,
} from "../src/routes.ts";

describe("GitHub Pages routing", () => {
  it("APP_ROUTES uses hash paths", () => {
    for (const route of Object.values(APP_ROUTES)) {
      assert.ok(route.startsWith("#/"), `expected hash route: ${route}`);
    }
  });

  it("hashToMode maps play route to match", () => {
    assert.equal(hashToMode(APP_ROUTES.play), "match");
    assert.equal(hashToMode(APP_ROUTES.impactDummyDerby), "impact-dummy-derby");
  });

  it("modeToHash round-trips home", () => {
    assert.equal(modeToHash("home"), APP_ROUTES.home);
  });

  it("assertPagesBaseInHtml checks vite base", () => {
    const html = '<script src="/anime-aggressors/assets/index.js"></script>';
    assert.equal(assertPagesBaseInHtml(html), true);
  });
});
