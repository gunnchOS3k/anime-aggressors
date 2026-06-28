import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { DEFAULT_FIGHTERS, getFighterMoveset } from "@anime-aggressors/game-core";
import { renderMoveCard } from "../src/ui/MoveCard.ts";
import { APP_ROUTES } from "../src/routes.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("move list screen", () => {
  it("defines moves hash route", () => {
    assert.equal(APP_ROUTES.moves, "#/moves");
  });

  it("screen reads fighter query param", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/screens/MoveListScreen.ts"), "utf8");
    assert.match(src, /fighterFromQuery/);
    assert.match(src, /get\("fighter"\)/);
    assert.match(src, /mountMoveListScreen/);
  });

  it("can display each fighter moveset via move cards", () => {
    for (const fighter of DEFAULT_FIGHTERS) {
      const moves = getFighterMoveset(fighter.id);
      assert.equal(moves.length, 19);
      const card = renderMoveCard({ move: moves[0]! });
      assert.match(card, /move-card/);
      assert.ok(card.includes(moves[0]!.displayName));
    }
  });
});
