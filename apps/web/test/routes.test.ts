import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { APP_ROUTES, hashToMode } from "../src/routes.ts";

describe("routes include create fighter", () => {
  it("has create-fighter route", () => {
    assert.equal(APP_ROUTES.createFighter, "#/create-fighter");
    assert.equal(hashToMode(APP_ROUTES.createFighter), "create-fighter");
  });

  it("has feedback route", () => {
    assert.equal(hashToMode(APP_ROUTES.feedback), "feedback");
  });
});
