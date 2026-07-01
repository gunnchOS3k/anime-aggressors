import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  getProductionFighters,
  getPreviewFighters,
  getPlayableRoster,
  getFighterGameplayProfile,
} from "@anime-aggressors/game-core";
import { buildSelectableRoster } from "../src/characterSelect/characterSelectState.ts";
import { renderCharacterTile } from "../src/ui/CharacterTile.ts";

describe("Milestone 4 web — roster presentation", () => {
  it("buildSelectableRoster includes all seven default fighters", () => {
    const roster = buildSelectableRoster();
    const ids = roster.map((f) => f.id);
    assert.ok(ids.includes("ember-vale"));
    assert.ok(ids.includes("vesper-nyx"));
    assert.equal(ids.filter((id) => getPlayableRoster().some((p) => p.id === id)).length, 7);
  });

  it("production fighters count is four", () => {
    assert.equal(getProductionFighters().length, 4);
    assert.equal(getPreviewFighters().length, 3);
  });

  it("character tile renders production badge for ember-vale", () => {
    const fighter = buildSelectableRoster().find((f) => f.id === "ember-vale")!;
    const html = renderCharacterTile({ fighter, state: "default" });
    assert.match(html, /cs-tile-badge--production/);
    assert.match(html, /Production/);
  });

  it("character tile renders preview badge for vesper-nyx", () => {
    const fighter = buildSelectableRoster().find((f) => f.id === "vesper-nyx")!;
    const html = renderCharacterTile({ fighter, state: "default" });
    assert.match(html, /cs-tile-badge--preview/);
    assert.match(html, /Preview/);
  });

  it("every playable fighter has gameplay profile", () => {
    for (const f of getPlayableRoster()) {
      const profile = getFighterGameplayProfile(f.id);
      assert.ok(profile);
      assert.ok(["production", "preview"].includes(profile!.status));
    }
  });
});
