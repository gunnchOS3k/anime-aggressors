import type { GestureEvent, SensorFrame } from "@anime-aggressors/messages";

export function detectGestures(buffer: SensorFrame[]): GestureEvent[] {
  const events: GestureEvent[] = [];
  if (buffer.length < 2) return events;
  
  const last = buffer[buffer.length - 1];
  const prev = buffer[buffer.length - 2];
  const dax = last.ax - prev.ax;
  const day = last.ay - prev.ay;
  const daz = last.az - prev.az;
  
  // Simple threshold-based detection
  if (dax > 1200 && Math.abs(day) < 500) {
    events.push({ type: "swipeR", t: last.t });
  }
  if (dax < -1200 && Math.abs(day) < 500) {
    events.push({ type: "swipeL", t: last.t });
  }
  if (daz > 2000 && Math.abs(dax) < 600) {
    events.push({ type: "thrust", t: last.t });
  }
  if (Math.abs(day) < 200 && Math.abs(dax) < 200 && Math.abs(daz) < 200) {
    events.push({ type: "block", t: last.t });
  }
  
  return events;
}

export function createGestureBuffer(maxSize = 10): SensorFrame[] {
  return [];
}

export function addToBuffer(buffer: SensorFrame[], frame: SensorFrame, maxSize = 10): SensorFrame[] {
  const newBuffer = [...buffer, frame];
  return newBuffer.length > maxSize ? newBuffer.slice(-maxSize) : newBuffer;
}
