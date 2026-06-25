import {
  cloneGameState,
  hashState,
  replay,
  simulateFrame,
  type GameState,
  type InputFrame,
} from "@anime-aggressors/game-core";
import type { RollbackEvent, RollbackSessionConfig, RollbackStats } from "./types.js";

type FrameRecord = {
  frame: number;
  inputs: InputFrame[];
  confirmed: boolean[];
  state: GameState;
  hash: string;
};

export class RollbackSession {
  private currentFrame = 0;
  private state: GameState;
  private history: FrameRecord[] = [];
  private confirmedInputs: Map<string, InputFrame> = new Map();
  private predictedInputs: Map<string, InputFrame> = new Map();
  private stats: RollbackStats = {
    rollbackCount: 0,
    lastRollbackFrame: -1,
    desyncDetected: false,
    expectedHash: null,
    actualHash: null,
  };
  private events: RollbackEvent[] = [];

  constructor(
    initialState: GameState,
    private config: RollbackSessionConfig,
  ) {
    this.state = cloneGameState(initialState);
    this.snapshot(0, [], []);
  }

  private inputKey(frame: number, playerId: number): string {
    return `${frame}:${playerId}`;
  }

  private defaultInput(frame: number, playerId: number): InputFrame {
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

  private snapshot(frame: number, inputs: InputFrame[], confirmed: boolean[]): void {
    const state = cloneGameState(this.state);
    const hash = hashState(state);
    this.history.push({ frame, inputs: inputs.map((i) => ({ ...i })), confirmed: [...confirmed], state, hash });

    while (this.history.length > this.config.maxRollbackFrames + 1) {
      this.history.shift();
    }
  }

  /** Advance one frame using predicted inputs for unconfirmed slots. */
  advanceFrame(inputs: InputFrame[], confirmed: boolean[]): GameState {
    const frame = this.currentFrame;
    const resolved: InputFrame[] = [];

    for (let p = 0; p < this.config.playerCount; p++) {
      const key = this.inputKey(frame, p);
      const provided = inputs.find((i) => i.playerId === p);
      const isConfirmed = confirmed[p] ?? false;

      if (provided && isConfirmed) {
        this.confirmedInputs.set(key, { ...provided, frame });
        resolved.push({ ...provided, frame });
      } else if (this.confirmedInputs.has(key)) {
        resolved.push({ ...this.confirmedInputs.get(key)!, frame });
      } else if (provided) {
        this.predictedInputs.set(key, { ...provided, frame });
        resolved.push({ ...provided, frame });
      } else if (this.predictedInputs.has(key)) {
        resolved.push({ ...this.predictedInputs.get(key)!, frame });
      } else {
        resolved.push(this.defaultInput(frame, p));
      }
    }

    this.state = simulateFrame(this.state, resolved);
    this.currentFrame += 1;
    this.snapshot(this.currentFrame, resolved, confirmed);

    return cloneGameState(this.state);
  }

  /** Confirm inputs for a past frame; rollback and resimulate if prediction was wrong. */
  confirmInputs(frame: number, inputs: InputFrame[]): GameState {
    let mismatch = false;

    for (const input of inputs) {
      const key = this.inputKey(frame, input.playerId);
      const predicted = this.predictedInputs.get(key);
      const prior = this.confirmedInputs.get(key);

      if (prior && inputsEqual(prior, input)) continue;

      this.confirmedInputs.set(key, { ...input, frame });

      if (predicted && !inputsEqual(predicted, input)) {
        mismatch = true;
      } else if (!prior && !predicted) {
        mismatch = true;
      }
    }

    if (!mismatch) {
      return cloneGameState(this.state);
    }

    const targetFrame = this.currentFrame;
    const recordIdx = this.history.findIndex((r) => r.frame === frame);
    if (recordIdx < 0) {
      return cloneGameState(this.state);
    }

    const rollbackTo = this.history[recordIdx].state;
    this.state = cloneGameState(rollbackTo);
    this.currentFrame = frame;

    this.stats.rollbackCount += 1;
    this.stats.lastRollbackFrame = frame;
    this.events.push({
      type: "rollback",
      fromFrame: targetFrame,
      toFrame: frame,
      count: 1,
    });

    this.history = this.history.slice(0, recordIdx + 1);

    while (this.currentFrame < targetFrame) {
      const f = this.currentFrame;
      const frameInputs: InputFrame[] = [];
      const confirmed: boolean[] = [];

      for (let p = 0; p < this.config.playerCount; p++) {
        const key = this.inputKey(f, p);
        const confirmedInput = this.confirmedInputs.get(key);
        if (confirmedInput) {
          frameInputs.push({ ...confirmedInput, frame: f });
          confirmed.push(true);
        } else {
          const predicted = this.predictedInputs.get(key) ?? this.defaultInput(f, p);
          frameInputs.push({ ...predicted, frame: f });
          confirmed.push(false);
        }
      }

      this.state = simulateFrame(this.state, frameInputs);
      this.currentFrame += 1;
      this.snapshot(this.currentFrame, frameInputs, confirmed);
    }

    return cloneGameState(this.state);
  }

  /** Verify current state against authoritative replay from a snapshot. */
  verifyAgainstReplay(fromState: GameState, inputLog: InputFrame[][]): boolean {
    const result = replay(fromState, inputLog);
    const actual = hashState(this.state);
    this.stats.expectedHash = result.finalHash;
    this.stats.actualHash = actual;

    if (result.finalHash !== actual) {
      this.stats.desyncDetected = true;
      this.events.push({
        type: "desync",
        frame: this.currentFrame,
        expected: result.finalHash,
        actual,
      });
      return false;
    }
    return true;
  }

  getState(): GameState {
    return cloneGameState(this.state);
  }

  getFrame(): number {
    return this.currentFrame;
  }

  getStats(): RollbackStats {
    return { ...this.stats };
  }

  getEvents(): RollbackEvent[] {
    return [...this.events];
  }

  getRollbackCount(): number {
    return this.stats.rollbackCount;
  }
}

function inputsEqual(a: InputFrame, b: InputFrame): boolean {
  return (
    a.left === b.left &&
    a.right === b.right &&
    a.up === b.up &&
    a.down === b.down &&
    a.jump === b.jump &&
    a.attack === b.attack &&
    a.special === b.special &&
    a.shield === b.shield &&
    a.dodge === b.dodge &&
    a.grab === b.grab &&
    a.wearableGesture === b.wearableGesture
  );
}

export { inputsEqual };
