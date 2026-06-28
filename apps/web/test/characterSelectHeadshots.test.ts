import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getAllDefaultCreatedFighters } from "@anime-aggressors/game-core";
import { renderCharacterTile } from "../src/ui/CharacterTile.ts";

describe("character select headshots", () => {
  it("portrait tile includes fighter name, element, size, and portrait visual", () => {
    for (const fighter of getAllDefaultCreatedFighters()) {
      const html = renderCharacterTile({ fighter, state: "idle", tabIndex: 0 });
      assert.match(html, /character-portrait-tile/);
      assert.match(html, /fighter-portrait/);
      assert.match(html, new RegExp(fighter.name));
      assert.match(html, /cs-tile-element/);
      assert.match(html, /cs-tile-size/);
    }
  });

  it("selected tile shows P1 marker", () => {
    const fighter = getAllDefaultCreatedFighters()[0]!;
    const html = renderCharacterTile({ fighter, state: "p1", tabIndex: 0 });
    assert.match(html, /P1/);
  });
});
