import type { GestureName } from "./gestures.js";
import { normalizeGestureId } from "./gestures.js";

/** 22-byte SensorNotify packet (little-endian). */
export type SensorNotify = {
  seq: number;
  timestampMs: number;
  ax: number;
  ay: number;
  az: number;
  gx: number;
  gy: number;
  gz: number;
  batteryPct: number;
  flags: number;
};

/** 12-byte GestureNotify packet. */
export type GestureNotify = {
  seq: number;
  timestampMs: number;
  gestureId: number;
  confidence: number;
  deviceId: number;
  gesture: GestureName;
};

/** 4-byte HapticWrite packet. */
export type HapticWrite = {
  effectId: number;
  intensity: number;
  durationMs: number;
};

export const SENSOR_PACKET_SIZE = 22;
export const GESTURE_PACKET_SIZE = 12;
export const HAPTIC_PACKET_SIZE = 4;

export function parseSensorPacket(dv: DataView): SensorNotify {
  return {
    seq: dv.getUint32(0, true),
    timestampMs: dv.getUint32(4, true),
    ax: dv.getInt16(8, true),
    ay: dv.getInt16(10, true),
    az: dv.getInt16(12, true),
    gx: dv.getInt16(14, true),
    gy: dv.getInt16(16, true),
    gz: dv.getInt16(18, true),
    batteryPct: dv.getUint8(20),
    flags: dv.getUint8(21),
  };
}

export function parseGesturePacket(dv: DataView): GestureNotify {
  const gestureId = dv.getUint8(8);
  return {
    seq: dv.getUint32(0, true),
    timestampMs: dv.getUint32(4, true),
    gestureId,
    confidence: dv.getUint8(9),
    deviceId: dv.getUint8(10),
    gesture: normalizeGestureId(gestureId),
  };
}

export function createGesturePacket(
  seq: number,
  timestampMs: number,
  gesture: GestureName,
  confidence = 100,
  deviceId = 0,
): Uint8Array {
  const bytes = new Uint8Array(GESTURE_PACKET_SIZE);
  const dv = new DataView(bytes.buffer);
  dv.setUint32(0, seq, true);
  dv.setUint32(4, timestampMs, true);
  dv.setUint8(8, gestureNameToId(gesture));
  dv.setUint8(9, confidence);
  dv.setUint8(10, deviceId);
  dv.setUint8(11, 0);
  return bytes;
}

export function parseHapticPacket(dv: DataView): HapticWrite {
  return {
    effectId: dv.getUint8(0),
    intensity: dv.getUint8(1),
    durationMs: dv.getUint16(2, true),
  };
}

export function createHapticPacket(cmd: HapticWrite): Uint8Array {
  const bytes = new Uint8Array(HAPTIC_PACKET_SIZE);
  const dv = new DataView(bytes.buffer);
  dv.setUint8(0, cmd.effectId);
  dv.setUint8(1, cmd.intensity);
  dv.setUint16(2, cmd.durationMs, true);
  return bytes;
}

export function createSensorPacket(sensor: SensorNotify): Uint8Array {
  const bytes = new Uint8Array(SENSOR_PACKET_SIZE);
  const dv = new DataView(bytes.buffer);
  dv.setUint32(0, sensor.seq, true);
  dv.setUint32(4, sensor.timestampMs, true);
  dv.setInt16(8, sensor.ax, true);
  dv.setInt16(10, sensor.ay, true);
  dv.setInt16(12, sensor.az, true);
  dv.setInt16(14, sensor.gx, true);
  dv.setInt16(16, sensor.gy, true);
  dv.setInt16(18, sensor.gz, true);
  dv.setUint8(20, sensor.batteryPct);
  dv.setUint8(21, sensor.flags);
  return bytes;
}

function gestureNameToId(name: GestureName): number {
  const map: Record<GestureName, number> = {
    tap: 0,
    swipeL: 1,
    swipeR: 2,
    swipeU: 3,
    swipeD: 4,
    thrust: 5,
    doubleTap: 6,
    block: 7,
    shake: 8,
  };
  return map[name];
}

export function makeDataView(bytes: Uint8Array): DataView {
  return new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
}
