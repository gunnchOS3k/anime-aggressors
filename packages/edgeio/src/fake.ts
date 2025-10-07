import { makeDataView, parseSensorPacket } from "./parser.js";

export function generateFakePacket({ t = 0, ax = 0, ay = 0, az = 0, gx = 0, gy = 0, gz = 0 } = {}) {
  const bytes = new Uint8Array(14);
  const dv = new DataView(bytes.buffer);
  dv.setUint16(0, t, true);
  dv.setInt16(2, ax, true);
  dv.setInt16(4, ay, true);
  dv.setInt16(6, az, true);
  dv.setInt16(8, gx, true);
  dv.setInt16(10, gy, true);
  dv.setInt16(12, gz, true);
  return bytes;
}

export function generateFrames(n: number) {
  const frames = [];
  for (let i = 0; i < n; i++) {
    const bytes = generateFakePacket({ 
      t: i, 
      ax: i * 50, 
      ay: 0, 
      az: i === n - 1 ? 2100 : 0 
    });
    frames.push(parseSensorPacket(makeDataView(bytes)));
  }
  return frames;
}

export function generateSwipeRightSequence() {
  return generateFrames(5).map((frame, i) => ({
    ...frame,
    ax: i === 4 ? 1400 : frame.ax
  }));
}
