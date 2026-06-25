import type { GestureName, InputFrame } from "@anime-aggressors/game-core";

export type { InputFrame, GestureName };

export function emptyInputFrame(frame: number, playerId: number): InputFrame {
  return {
    frame,
    playerId,
    left: false,
    right: false,
    up: false,
    down: false,
    jump: false,
    attack: false,
    special: false,
    shield: false,
    dodge: false,
    grab: false,
  };
}

export function mergeInputFrame(base: InputFrame, partial: Partial<InputFrame>): InputFrame {
  return { ...base, ...partial };
}
