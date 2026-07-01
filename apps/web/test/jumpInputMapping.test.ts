import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { KEYBOARD_P1_BINDINGS, KEYBOARD_P2_BINDINGS } from "../src/input/inputProfiles.ts";
import { actionsToInputFrame, resolveProfileActions } from "../src/input/profileInput.ts";
import { getDefaultProfileForSlot } from "../src/input/inputProfiles.ts";

describe("jump input mapping", () => {
  it("P1 jump key is Space with W as alternate", () => {
    assert.equal(KEYBOARD_P1_BINDINGS.jump?.code, "Space");
    assert.equal(KEYBOARD_P1_BINDINGS.moveUp?.code, "KeyW");
  });

  it("P2 jump keys are Numpad0 and ArrowUp", () => {
    assert.equal(KEYBOARD_P2_BINDINGS.jump?.code, "Numpad0");
    const profile = getDefaultProfileForSlot(2);
    const actions = resolveProfileActions(profile, new Set(["ArrowUp"]), null);
    assert.equal(actions.jump, true);
  });

  it("actionsToInputFrame sets jump", () => {
    const frame = actionsToInputFrame(0, 0, { jump: true });
    assert.equal(frame.jump, true);
  });

  it("P1 Space sets InputFrame.jump", () => {
    const profile = getDefaultProfileForSlot(1);
    const keys = new Set(["Space"]);
    const actions = resolveProfileActions(profile, keys, null);
    const frame = actionsToInputFrame(0, 0, actions);
    assert.equal(frame.jump, true);
  });
});
