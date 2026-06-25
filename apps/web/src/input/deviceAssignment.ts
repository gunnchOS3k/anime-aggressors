/**
 * Device assignment: maps physical devices to player slots.
 * Keyboard P1 always available; P2 uses keyboard or gamepad 1.
 */

import type { InputFrame } from "./inputFrame.js";
import { pollKeyboardP1, pollKeyboardP2 } from "./keyboard.js";
import { getConnectedGamepads, pollGamepad } from "./gamepad.js";
import { applyEdgeIOGesture, type EdgeIOMapperConfig } from "./edgeioMapper.js";

export type PlayerSlot = 0 | 1;

export type DeviceAssignment = {
  p1: "keyboard" | "gamepad0";
  p2: "keyboard" | "gamepad1";
};

const defaultAssignment: DeviceAssignment = {
  p1: "keyboard",
  p2: "keyboard",
};

let assignment: DeviceAssignment = { ...defaultAssignment };

export function getDeviceAssignment(): DeviceAssignment {
  const pads = getConnectedGamepads();
  return {
    p1: pads[0] ? "gamepad0" : "keyboard",
    p2: pads[1] ? "gamepad1" : "keyboard",
  };
}

export function pollPlayerInput(
  frame: number,
  playerId: PlayerSlot,
  edgeConfig?: EdgeIOMapperConfig,
  wearableGesture?: InputFrame["wearableGesture"],
): InputFrame {
  assignment = getDeviceAssignment();
  const pads = getConnectedGamepads();

  let input: InputFrame;

  if (playerId === 0) {
    if (assignment.p1 === "gamepad0" && pads[0]) {
      input = pollGamepad(pads[0], frame, 0);
    } else {
      input = pollKeyboardP1(frame, 0);
    }
  } else {
    if (assignment.p2 === "gamepad1" && pads[1]) {
      input = pollGamepad(pads[1], frame, 1);
    } else {
      input = pollKeyboardP2(frame, 1);
    }
  }

  if (wearableGesture && edgeConfig) {
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
