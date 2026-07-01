import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { getDefaultProfileForSlot } from "../src/input/inputProfiles.ts";
import {
  detectBindingConflict,
  applyBinding,
  captureKeyboardBinding,
  captureGamepadButton,
  remapFromKeyboardCode,
  remapFromGamepadButton,
} from "../src/input/remapInput.ts";

describe("inputRemap", () => {
  it("remap captures keyboard binding", () => {
    const profile = getDefaultProfileForSlot(1);
    const result = remapFromKeyboardCode(profile, "attack", "KeyQ", true);
    assert.equal(result.profile.bindings.attack?.device, "keyboard");
    assert.equal((result.profile.bindings.attack as { code: string }).code, "KeyQ");
  });

  it("remap captures gamepad binding", () => {
    const profile = getDefaultProfileForSlot(1);
    const result = remapFromGamepadButton(profile, "jump", 3, true);
    assert.equal(result.profile.bindings.jump?.device, "gamepad");
    assert.equal((result.profile.bindings.jump as { index: number }).index, 3);
  });

  it("conflict detection works", () => {
    const profile = getDefaultProfileForSlot(1);
    const binding = captureKeyboardBinding("KeyJ");
    const conflict = detectBindingConflict(profile, "special", binding);
    assert.ok(conflict);
    assert.equal(conflict?.action, "attack");
    const applied = applyBinding(profile, "special", binding, true);
    assert.equal((applied.profile.bindings.special as { code: string }).code, "KeyJ");
    assert.equal(applied.profile.bindings.attack, undefined);
  });

  it("capture helpers shape bindings", () => {
    assert.deepEqual(captureKeyboardBinding("Space"), { device: "keyboard", code: "Space" });
    assert.deepEqual(captureGamepadButton(1), { device: "gamepad", kind: "button", index: 1 });
  });
});
