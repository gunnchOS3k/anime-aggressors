/**
 * Profile-based device assignment — maps input profiles to player slots.
 */

import type { InputFrame } from "./inputFrame.ts";
import { getPressedKeyCodes } from "./keyboard.ts";
import { getConnectedGamepads, gamepadToState } from "./gamepad.ts";
import { profileToInputFrame } from "./profileInput.ts";
import { getProfileForSlot } from "../storage/inputProfileStorage.ts";
import { applyEdgeIOGesture, type EdgeIOMapperConfig } from "./edgeioMapper.ts";

export type PlayerSlot = 0 | 1 | 2 | 3;

export function pollPlayerInput(
  frame: number,
  playerId: PlayerSlot,
  edgeConfig?: EdgeIOMapperConfig,
  wearableGesture?: InputFrame["wearableGesture"],
): InputFrame {
  const slot = (playerId + 1) as 1 | 2 | 3 | 4;
  const profile = getProfileForSlot(slot);
  const keyboard = getPressedKeyCodes();
  const pads = getConnectedGamepads();
  const padIndex = profile.deviceType === "gamepad" ? playerId : playerId;
  const gamepad = pads[padIndex] ? gamepadToState(pads[padIndex]!) : null;

  let input = profileToInputFrame(
    frame,
    playerId,
    profile,
    keyboard,
    gamepad,
    wearableGesture,
  );

  if (wearableGesture && edgeConfig && profile.deviceType === "edgeio") {
    input = applyEdgeIOGesture(input, wearableGesture, edgeConfig);
  }

  return input;
}

export function pollAllInputs(
  frame: number,
  edgeGestures: Partial<Record<PlayerSlot, InputFrame["wearableGesture"]>> = {},
  edgeConfig?: EdgeIOMapperConfig,
): InputFrame[] {
  return [
    pollPlayerInput(frame, 0, edgeConfig, edgeGestures[0]),
    pollPlayerInput(frame, 1, edgeConfig, edgeGestures[1]),
  ];
}

export function getSlotProfileSummary(slot: 1 | 2 | 3 | 4): { name: string; deviceType: string } {
  const profile = getProfileForSlot(slot);
  return { name: profile.name, deviceType: profile.deviceType };
}
