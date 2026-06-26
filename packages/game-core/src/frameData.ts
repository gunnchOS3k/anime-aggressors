/** Frame data for platform-fighter moves (startup / active / recovery). */
export type MoveFrameData = {
  move: string;
  startup: number;
  active: number;
  recovery: number;
  damage: number;
  baseKnockback: number;
  knockbackGrowth: number;
  hitstop: number;
  cancelWindows: number[];
};

export const FORWARD_ATTACK: MoveFrameData = {
  move: "forward_attack",
  startup: 5,
  active: 3,
  recovery: 14,
  damage: 7,
  baseKnockback: 9,
  knockbackGrowth: 1.25,
  hitstop: 5,
  cancelWindows: [12],
};

export const UP_ATTACK: MoveFrameData = {
  move: "up_attack",
  startup: 6,
  active: 4,
  recovery: 16,
  damage: 8,
  baseKnockback: 10,
  knockbackGrowth: 1.2,
  hitstop: 6,
  cancelWindows: [],
};

export const DOWN_ATTACK: MoveFrameData = {
  move: "down_attack",
  startup: 4,
  active: 3,
  recovery: 10,
  damage: 5,
  baseKnockback: 6,
  knockbackGrowth: 1.1,
  hitstop: 4,
  cancelWindows: [],
};

export const AERIAL_ATTACK: MoveFrameData = {
  move: "aerial_attack",
  startup: 3,
  active: 4,
  recovery: 18,
  damage: 6,
  baseKnockback: 7,
  knockbackGrowth: 1.15,
  hitstop: 4,
  cancelWindows: [],
};

export const SIDE_SPECIAL: MoveFrameData = {
  move: "side_special",
  startup: 10,
  active: 5,
  recovery: 20,
  damage: 14,
  baseKnockback: 16,
  knockbackGrowth: 1.35,
  hitstop: 8,
  cancelWindows: [],
};

export const NEUTRAL_ATTACK: MoveFrameData = {
  move: "neutral_attack",
  startup: 4,
  active: 3,
  recovery: 12,
  damage: 6,
  baseKnockback: 8,
  knockbackGrowth: 1.2,
  hitstop: 5,
  cancelWindows: [],
};

export const SPECIAL_ATTACK: MoveFrameData = {
  move: "special_attack",
  startup: 8,
  active: 4,
  recovery: 18,
  damage: 12,
  baseKnockback: 14,
  knockbackGrowth: 1.4,
  hitstop: 8,
  cancelWindows: [],
};

export const DODGE_MOVE: MoveFrameData = {
  move: "dodge",
  startup: 2,
  active: 8,
  recovery: 6,
  damage: 0,
  baseKnockback: 0,
  knockbackGrowth: 0,
  hitstop: 0,
  cancelWindows: [],
};

export function totalMoveFrames(data: MoveFrameData): number {
  return data.startup + data.active + data.recovery;
}

export function isInStartup(data: MoveFrameData, actionFrame: number): boolean {
  return actionFrame >= 1 && actionFrame < data.startup;
}

export function isInActive(data: MoveFrameData, actionFrame: number): boolean {
  return actionFrame >= data.startup && actionFrame < data.startup + data.active;
}

export function isInRecovery(data: MoveFrameData, actionFrame: number): boolean {
  return actionFrame >= data.startup + data.active && actionFrame <= totalMoveFrames(data);
}
