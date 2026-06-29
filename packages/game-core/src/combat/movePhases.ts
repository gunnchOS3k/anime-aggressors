export type MovePhase =
  | "idle"
  | "startup"
  | "active"
  | "impactFreeze"
  | "recovery"
  | "cancelWindow";

export type FightingMoveTiming = {
  startupFrames: number;
  activeFrames: number;
  recoveryFrames: number;
  cancelStartFrame?: number;
  cancelEndFrame?: number;
  hitstopFrames: number;
};

export function totalMoveFrames(timing: FightingMoveTiming): number {
  return timing.startupFrames + timing.activeFrames + timing.recoveryFrames;
}

export function getMovePhase(actionFrame: number, timing: FightingMoveTiming): MovePhase {
  if (actionFrame < timing.startupFrames) return "startup";
  const activeEnd = timing.startupFrames + timing.activeFrames;
  if (actionFrame < activeEnd) return "active";
  const recoveryEnd = activeEnd + timing.recoveryFrames;
  if (actionFrame < recoveryEnd) {
    const cancelStart = timing.cancelStartFrame ?? activeEnd;
    const cancelEnd = timing.cancelEndFrame ?? recoveryEnd;
    if (actionFrame >= cancelStart && actionFrame < cancelEnd) return "cancelWindow";
    return "recovery";
  }
  return "idle";
}

export function fightingTimingFromFrameData(data: {
  startup: number;
  active: number;
  recovery: number;
  hitstop?: number;
}): FightingMoveTiming {
  return {
    startupFrames: data.startup,
    activeFrames: data.active,
    recoveryFrames: data.recovery,
    hitstopFrames: data.hitstop ?? 0,
    cancelStartFrame: data.startup + data.active,
  };
}
