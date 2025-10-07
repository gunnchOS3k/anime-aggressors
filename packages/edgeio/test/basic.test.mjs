import assert from 'node:assert/strict';
import { parseSensorPacket, makeDataView, createHapticPacket } from '../src/parser.js';
import { detectGestures } from '../src/gestures.js';
import { generateFakePacket, generateSwipeRightSequence } from '../src/fake.js';

// Test sensor packet parsing
const bytes = new Uint8Array(14);
const dv = new DataView(bytes.buffer);
dv.setUint16(0, 42, true);
dv.setInt16(2, 1000, true);
dv.setInt16(4, 0, true);
dv.setInt16(6, 0, true);
dv.setInt16(8, 0, true);
dv.setInt16(10, 0, true);
dv.setInt16(12, 0, true);

const frame = parseSensorPacket(makeDataView(bytes));
assert.equal(frame.t, 42);
assert.equal(frame.ax, 1000);

// Test gesture detection
const gestures = detectGestures([
  {t:41,ax:0,ay:0,az:0,gx:0,gy:0,gz:0},
  {t:42,ax:1400,ay:0,az:0,gx:0,gy:0,gz:0}
]);
assert.ok(gestures.find(g => g.type === 'swipeR'));

// Test haptic packet creation
const hapticCmd = createHapticPacket({ effectId: 1, intensity: 128, durationMs: 500 });
assert.equal(hapticCmd.length, 4);
assert.equal(hapticCmd[0], 1);
assert.equal(hapticCmd[1], 128);

// Test fake data generation
const fakeFrames = generateSwipeRightSequence();
assert.equal(fakeFrames.length, 5);
assert.equal(fakeFrames[4].ax, 1400);

console.log('All tests passed!');
