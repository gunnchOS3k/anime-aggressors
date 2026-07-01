import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  KEYBOARD_P1_BINDINGS,
  KEYBOARD_P2_BINDINGS,
  getDefaultProfileForSlot,
} from "../src/input/inputProfiles.ts";
import { actionsToInputFrame, resolveProfileActions } from "../src/input/profileInput.ts";

describe("canonical P1/P2 keyboard mapping", () => {
  it("P1 move keys are A and D", () => {
    assert.equal(KEYBOARD_P1_BINDINGS.moveLeft?.code, "KeyA");
    assert.equal(KEYBOARD_P1_BINDINGS.moveRight?.code, "KeyD");
  });

  it("P1 jump keys are W (via moveUp/tapJump) and Space", () => {
    assert.equal(KEYBOARD_P1_BINDINGS.jump?.code, "Space");
    assert.equal(KEYBOARD_P1_BINDINGS.moveUp?.code, "KeyW");
    const profile = getDefaultProfileForSlot(1);
    const keys = new Set(["KeyW", "Space"]);
    const actions = resolveProfileActions(profile, keys, null);
    assert.equal(actions.jump, true);
  });

  it("P1 attack/special/shield are J/K/L", () => {
    assert.equal(KEYBOARD_P1_BINDINGS.attack?.code, "KeyJ");
    assert.equal(KEYBOARD_P1_BINDINGS.special?.code, "KeyK");
    assert.equal(KEYBOARD_P1_BINDINGS.shield?.code, "KeyL");
  });

  it("P2 move keys are arrow keys", () => {
    assert.equal(KEYBOARD_P2_BINDINGS.moveLeft?.code, "ArrowLeft");
    assert.equal(KEYBOARD_P2_BINDINGS.moveRight?.code, "ArrowRight");
  });

  it("P2 jump keys are ArrowUp and Numpad0", () => {
    assert.equal(KEYBOARD_P2_BINDINGS.jump?.code, "Numpad0");
    const profile = getDefaultProfileForSlot(2);
    const keys = new Set(["ArrowUp", "Numpad0"]);
    const actions = resolveProfileActions(profile, keys, null);
    assert.equal(actions.jump, true);
  });

  it("P2 combat keys use numpad 1-5", () => {
    assert.equal(KEYBOARD_P2_BINDINGS.attack?.code, "Numpad1");
    assert.equal(KEYBOARD_P2_BINDINGS.special?.code, "Numpad2");
    assert.equal(KEYBOARD_P2_BINDINGS.shield?.code, "Numpad3");
    assert.equal(KEYBOARD_P2_BINDINGS.dodge?.code, "Numpad4");
    assert.equal(KEYBOARD_P2_BINDINGS.grab?.code, "Numpad5");
  });

  it("P2 aura charge is Slash", () => {
    assert.equal(KEYBOARD_P2_BINDINGS.auraCharge?.code, "Slash");
  });

  it("actionsToInputFrame sets jump from resolved actions", () => {
    const frame = actionsToInputFrame(0, 0, { jump: true });
    assert.equal(frame.jump, true);
  });
});
