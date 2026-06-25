/** Canonical normalized gesture names (Edge-IO protocol). */
export type GestureName =
  | "swipeL"
  | "swipeR"
  | "swipeU"
  | "swipeD"
  | "thrust"
  | "tap"
  | "doubleTap"
  | "block"
  | "shake";

export const GESTURE_IDS: Record<number, GestureName> = {
  0: "tap",
  1: "swipeL",
  2: "swipeR",
  3: "swipeU",
  4: "swipeD",
  5: "thrust",
  6: "doubleTap",
  7: "block",
  8: "shake",
};

export const GESTURE_NAME_TO_ID: Record<GestureName, number> = {
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

export function normalizeGestureId(id: number): GestureName {
  return GESTURE_IDS[id] ?? "tap";
}

export function gestureNameToId(name: GestureName): number {
  return GESTURE_NAME_TO_ID[name];
}
