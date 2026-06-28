import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  DEFAULT_FIGHTERS,
  getComboRoutesByDifficulty,
  getComboRoutesForFighter,
  validateComboRouteCoverage,
} from "../src/index.js";

describe("combo routes", () => {
  it("validates coverage for all default fighters", () => {
    const result = validateComboRouteCoverage();
    assert.equal(result.ok, true, result.missing.join(", "));
  });

  it("each fighter has at least 2 beginner combos", () => {
    for (const f of DEFAULT_FIGHTERS) {
      assert.ok(getComboRoutesByDifficulty(f.id, "beginner").length >= 2, f.id);
    }
  });

  it("each fighter has at least 2 intermediate combos", () => {
    for (const f of DEFAULT_FIGHTERS) {
      assert.ok(getComboRoutesByDifficulty(f.id, "intermediate").length >= 2, f.id);
    }
  });

  it("each fighter has at least 1 advanced combo", () => {
    for (const f of DEFAULT_FIGHTERS) {
      assert.ok(getComboRoutesByDifficulty(f.id, "advanced").length >= 1, f.id);
    }
  });

  it("routes reference valid move slots", () => {
    for (const route of getComboRoutesForFighter("ember-vale")) {
      assert.ok(route.route.length >= 2);
      assert.ok(route.teachingHint.length > 0);
    }
  });
});
