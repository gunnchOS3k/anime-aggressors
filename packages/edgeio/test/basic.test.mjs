import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  parseSensorPacket,
  parseGesturePacket,
  createHapticPacket,
  createGesturePacket,
  makeDataView,
  mapGestureToInput,
  SENSOR_PACKET_SIZE,
  GESTURE_PACKET_SIZE,
  HAPTIC_PACKET_SIZE,
} from "../dist/index.js";

describe("edgeio protocol", () => {
  it("parses sensor packet", () => {
    const bytes = new Uint8Array(SENSOR_PACKET_SIZE);
    const dv = new DataView(bytes.buffer);
    dv.setUint32(0, 42, true);
    dv.setUint32(4, 1000, true);
    dv.setInt16(8, 100, true);
    dv.setUint8(20, 90);

    const parsed = parseSensorPacket(makeDataView(bytes));
    assert.equal(parsed.seq, 42);
    assert.equal(parsed.timestampMs, 1000);
    assert.equal(parsed.ax, 100);
    assert.equal(parsed.batteryPct, 90);
  });

  it("parses gesture packet", () => {
    const packet = createGesturePacket(7, 500, "swipeR", 95, 1);
    assert.equal(packet.byteLength, GESTURE_PACKET_SIZE);
    const parsed = parseGesturePacket(makeDataView(packet));
    assert.equal(parsed.gesture, "swipeR");
    assert.equal(parsed.confidence, 95);
    assert.equal(parsed.deviceId, 1);
  });

  it("encodes haptic packet", () => {
    const bytes = createHapticPacket({ effectId: 2, intensity: 200, durationMs: 150 });
    assert.equal(bytes.byteLength, HAPTIC_PACKET_SIZE);
    assert.equal(bytes[0], 2);
    assert.equal(bytes[1], 200);
  });

  it("maps wearable gesture to expected input action", () => {
    const mapped = mapGestureToInput("doubleTap");
    assert.equal(mapped.special, true);
    assert.equal(mapped.wearableGesture, "doubleTap");
  });
});
