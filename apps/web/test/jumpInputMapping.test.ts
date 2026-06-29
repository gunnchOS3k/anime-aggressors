import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { KEYBOARD_P1_BINDINGS, KEYBOARD_P2_BINDINGS } from "../src/input/inputProfiles.ts";
import { actionsToInputFrame, resolveProfileActions } from "../src/input/profileInput.ts";
import { getDefaultProfileForSlot } from "../src/input/inputProfiles.ts";

describe("jump input mapping", () => {
  it("P1 jump key is Space", () => {
    assert.equal(KEYBOARD_P1_BINDINGS.jump?.code, "Space");
  });

  it("P2 jump key is KeyW", () => {
    assert.equal(KEYBOARD_P2_BINDINGS.jump?.code, "KeyW");
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
