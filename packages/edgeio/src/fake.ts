import type { GestureName } from "./gestures.js";
import { createGesturePacket, createSensorPacket, type SensorNotify } from "./parser.js";

export function generateFakeSensorFrame(seq: number, timestampMs: number): SensorNotify {
  return {
    seq,
    timestampMs,
    ax: Math.sin(seq * 0.1) * 1000,
    ay: 0,
    az: 1000,
    gx: 0,
    gy: 0,
    gz: 0,
    batteryPct: 85,
    flags: 0,
  };
}

export function generateFakeGesturePacket(
  gesture: GestureName,
  seq = 1,
  timestampMs = 1000,
): Uint8Array {
  return createGesturePacket(seq, timestampMs, gesture);
}

export function generateSwipeRightSequence(count = 10): Uint8Array[] {
  const frames: Uint8Array[] = [];
  for (let i = 0; i < count; i++) {
    frames.push(
      createSensorPacket(generateFakeSensorFrame(i, i * 16)),
    );
  }
  frames.push(generateFakeGesturePacket("swipeR", count, count * 16));
  return frames;
}

export function generateFakePacket(type: "sensor" | "gesture", seq = 1): Uint8Array {
  if (type === "sensor") {
    return createSensorPacket(generateFakeSensorFrame(seq, seq * 16));
  }
  return generateFakeGesturePacket("tap", seq, seq * 16);
}
