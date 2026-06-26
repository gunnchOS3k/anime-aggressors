import type { GameAction } from "./actions.ts";
import type { InputBinding } from "./inputBindings.ts";
import { bindingKey, findActionForBinding } from "./inputBindings.ts";
import type { InputProfile } from "./inputProfiles.ts";
import { cloneProfile, getDefaultProfileForSlot } from "./inputProfiles.ts";

export type RemapConflict = {
  action: GameAction;
  binding: InputBinding;
};

export function detectBindingConflict(
  profile: InputProfile,
  action: GameAction,
  binding: InputBinding,
): RemapConflict | null {
  const key = bindingKey(binding);
  for (const [otherAction, otherBinding] of Object.entries(profile.bindings) as [GameAction, InputBinding][]) {
    if (!otherBinding || otherAction === action) continue;
    if (bindingKey(otherBinding) === key) {
      return { action: otherAction, binding: otherBinding };
    }
  }
  return null;
}

export function applyBinding(
  profile: InputProfile,
  action: GameAction,
  binding: InputBinding,
  replaceExisting = false,
): { profile: InputProfile; conflict: RemapConflict | null } {
  const next = cloneProfile(profile);
  const conflict = detectBindingConflict(next, action, binding);
  if (conflict && !replaceExisting) {
    return { profile: next, conflict };
  }
  if (conflict && replaceExisting) {
    delete next.bindings[conflict.action];
  }
  next.bindings[action] = binding;
  next.updatedAt = new Date().toISOString();
  return { profile: next, conflict };
}

export function resetActionBinding(profile: InputProfile, action: GameAction): InputProfile {
  const defaults = getDefaultProfileForSlot(profile.playerSlot);
  const next = cloneProfile(profile);
  if (defaults.bindings[action]) {
    next.bindings[action] = { ...defaults.bindings[action]! };
  } else {
    delete next.bindings[action];
  }
  next.updatedAt = new Date().toISOString();
  return next;
}

export function resetProfileBindings(profile: InputProfile): InputProfile {
  const defaults = getDefaultProfileForSlot(profile.playerSlot);
  return {
    ...cloneProfile(defaults),
    id: profile.id,
    name: profile.name,
    playerSlot: profile.playerSlot,
    deviceType: profile.deviceType,
    stickSensitivity: profile.stickSensitivity,
    deadzone: profile.deadzone,
    tapJumpEnabled: profile.tapJumpEnabled,
    rumbleEnabled: profile.rumbleEnabled,
    createdAt: profile.createdAt,
    updatedAt: new Date().toISOString(),
  };
}

export function captureKeyboardBinding(code: string): InputBinding {
  return { device: "keyboard", code };
}

export function captureGamepadButton(index: number): InputBinding {
  return { device: "gamepad", kind: "button", index };
}

export function captureGamepadAxis(
  index: number,
  direction: "positive" | "negative",
  threshold = 0.5,
): InputBinding {
  return { device: "gamepad", kind: "axis", index, direction, threshold };
}

export function findActionForRawBinding(
  profile: InputProfile,
  binding: InputBinding,
): GameAction | null {
  return findActionForBinding(profile.bindings, binding);
}

export function remapFromKeyboardCode(
  profile: InputProfile,
  action: GameAction,
  code: string,
  replace = false,
) {
  return applyBinding(profile, action, captureKeyboardBinding(code), replace);
}

export function remapFromGamepadButton(
  profile: InputProfile,
  action: GameAction,
  index: number,
  replace = false,
) {
  return applyBinding(profile, action, captureGamepadButton(index), replace);
}
