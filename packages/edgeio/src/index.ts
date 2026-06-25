export type { GestureName } from "./gestures.js";
export {
  GESTURE_IDS,
  GESTURE_NAME_TO_ID,
  normalizeGestureId,
  gestureNameToId,
} from "./gestures.js";

export {
  parseSensorPacket,
  parseGesturePacket,
  parseHapticPacket,
  createHapticPacket,
  createGesturePacket,
  createSensorPacket,
  makeDataView,
  SENSOR_PACKET_SIZE,
  GESTURE_PACKET_SIZE,
  HAPTIC_PACKET_SIZE,
  type SensorNotify,
  type GestureNotify,
  type HapticWrite,
} from "./parser.js";

export {
  generateFakePacket,
  generateFakeSensorFrame,
  generateFakeGesturePacket,
  generateSwipeRightSequence,
} from "./fake.js";

export { mapGestureToInput, type MappedInput } from "./inputMapper.js";

export { EdgeIO } from "./EdgeIO.js";
