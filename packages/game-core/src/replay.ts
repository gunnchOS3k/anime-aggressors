import type { GameState, InputFrame, ReplayResult } from "./types.js";
import { cloneGameState } from "./state.js";
import { simulateFrame } from "./simulate.js";
import { hashState } from "./hash.js";

export function replay(initial: GameState, inputLog: InputFrame[][]): ReplayResult {
  let state = cloneGameState(initial);
  const totalFrames = inputLog.length;

  for (let f = 0; f < totalFrames; f++) {
    const inputs = inputLog[f] ?? [];
    state = simulateFrame(state, inputs);
  }

  return {
    finalState: state,
    finalHash: hashState(state),
    framesSimulated: totalFrames,
  };
}
