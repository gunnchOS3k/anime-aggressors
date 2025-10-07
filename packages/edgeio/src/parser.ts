import type { SensorFrame, GestureEvent, HapticCommand, DeviceInfo } from "@anime-aggressors/messages";

// Parse 14-byte sensor packet: t:u16, ax..gz:i16
export function parseSensorPacket(dv: DataView): SensorFrame {
  const t = dv.getUint16(0, true);
  const ax = dv.getInt16(2, true);
  const ay = dv.getInt16(4, true);
  const az = dv.getInt16(6, true);
  const gx = dv.getInt16(8, true);
  const gy = dv.getInt16(10, true);
  const gz = dv.getInt16(12, true);
  return { t, ax, ay, az, gx, gy, gz };
}

// Parse 3-byte gesture event: type:u8, t:u16
export function parseGesturePacket(dv: DataView): GestureEvent {
  const type = dv.getUint8(0);
  const t = dv.getUint16(1, true);
  const gestureTypes = ["idle", "swipeL", "swipeR", "thrust", "block", "tap", "doubleTap", "shake"] as const;
  return { type: gestureTypes[type] || "idle", t };
}

// Parse 4-byte haptic command: effectId:u8, intensity:u8, durationMs:u16
export function parseHapticPacket(dv: DataView): HapticCommand {
  const effectId = dv.getUint8(0);
  const intensity = dv.getUint8(1);
  const durationMs = dv.getUint16(2, true);
  return { effectId, intensity, durationMs };
}

// Create haptic command packet
export function createHapticPacket(cmd: HapticCommand): Uint8Array {
  const bytes = new Uint8Array(4);
  const dv = new DataView(bytes.buffer);
  dv.setUint8(0, cmd.effectId);
  dv.setUint8(1, cmd.intensity);
  dv.setUint16(2, cmd.durationMs, true);
  return bytes;
}

// Parse device info JSON
export function parseDeviceInfo(json: string): DeviceInfo {
  return JSON.parse(json);
}

export function makeDataView(bytes: Uint8Array): DataView {
  return new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
}
