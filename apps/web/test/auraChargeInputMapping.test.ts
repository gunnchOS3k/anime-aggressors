import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { GAME_ACTIONS } from "../src/input/actions.ts";
import { KEYBOARD_P1_BINDINGS, KEYBOARD_P2_BINDINGS } from "../src/input/inputProfiles.ts";
import { actionsToInputFrame } from "../src/input/profileInput.ts";

describe("aura charge input mapping", () => {
  it("default actions include auraCharge", () => {
    assert.ok(GAME_ACTIONS.includes("auraCharge"));
  });

  it("P1 default profile binds KeyF", () => {
    assert.equal(KEYBOARD_P1_BINDINGS.auraCharge?.code, "KeyF");
  });

  it("P2 default profile binds Slash", () => {
    assert.equal(KEYBOARD_P2_BINDINGS.auraCharge?.code, "Slash");
  });

  it("actionsToInputFrame sets auraCharge from action", () => {
    const frame = actionsToInputFrame(0, 0, { auraCharge: true });
    assert.equal(frame.auraCharge, true);
  });

  it("shield+special also sets auraCharge", () => {
    const frame = actionsToInputFrame(0, 0, { shield: true, special: true });
    assert.equal(frame.auraCharge, true);
  });
});
