import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  DEFAULT_FIGHTERS,
  getComboRoutesForFighter,
} from "@anime-aggressors/game-core";
import { groupRoutesByDifficulty, renderComboRouteCard } from "../src/ui/ComboRouteCard.ts";
import { APP_ROUTES } from "../src/routes.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("combo guide", () => {
  it("defines combos hash route", () => {
    assert.equal(APP_ROUTES.combos, "#/combos");
  });

  it("screen groups routes by difficulty", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/screens/ComboGuideScreen.ts"), "utf8");
    assert.match(src, /groupRoutesByDifficulty/);
    assert.match(src, /Beginner Routes/);
    assert.match(src, /Intermediate Routes/);
    assert.match(src, /Advanced Routes/);
  });

  it("groups combo routes by difficulty for each fighter", () => {
    for (const fighter of DEFAULT_FIGHTERS) {
      const routes = getComboRoutesForFighter(fighter.id);
      const grouped = groupRoutesByDifficulty(routes);
      assert.ok(grouped.beginner.length >= 2, fighter.id);
      assert.ok(grouped.advanced.length >= 1, fighter.id);
      const card = renderComboRouteCard({
        route: routes[0]!,
        moveNames: { neutralAttack: "Test" },
      });
      assert.match(card, /combo-route-card/);
    }
  });
});
