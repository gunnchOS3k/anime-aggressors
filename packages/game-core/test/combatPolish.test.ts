import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  NEUTRAL_ATTACK,
  FORWARD_ATTACK,
  isInStartup,
  isInActive,
} from "../src/frameData.js";
import { getMoveData } from "../src/moves.js";
import { combatEventToSfx, createSfxEvent } from "../src/sfxEvents.js";
import { createCombatEvent } from "../src/combatEvents.js";

describe("combat polish", () => {
  it("expanded move list includes directional attacks", () => {
    assert.ok(getMoveData("forward_attack"));
    assert.ok(getMoveData("up_attack"));
    assert.ok(FORWARD_ATTACK.damage >= NEUTRAL_ATTACK.damage);
  });

  it("startup frames do not count as active", () => {
    assert.equal(isInActive(NEUTRAL_ATTACK, NEUTRAL_ATTACK.startup - 1), false);
    assert.equal(isInActive(NEUTRAL_ATTACK, NEUTRAL_ATTACK.startup), true);
    assert.equal(isInStartup(NEUTRAL_ATTACK, 2), true);
  });

  it("cancel windows exist on forward attack", () => {
    assert.ok(FORWARD_ATTACK.cancelWindows.length > 0);
  });

  it("combat events map to sfx events", () => {
    const sfx = combatEventToSfx(10, "hit_confirm", 0);
    assert.equal(sfx?.type, "hit_confirm");
    const menu = createSfxEvent(0, "menu_select");
    assert.equal(menu.type, "menu_select");
  });

  it("creates combat events with move id", () => {
    const ev = createCombatEvent(5, "attack_startup", 1, { moveId: "neutral_attack" });
    assert.equal(ev.moveId, "neutral_attack");
  });
});
