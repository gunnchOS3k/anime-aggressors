import type { GameState, InputFrame, ReplayInputFrame } from "@anime-aggressors/game-core";
import {
  createReplayRecord,
  hashState,
  serializeState,
  type ReplayRecord,
} from "@anime-aggressors/game-core";

export type ReplayRecorderOptions = {
  gameVersion: string;
  mode: string;
  ruleset: unknown;
  title?: string;
};

export class ReplayRecorder {
  private initialState: GameState | null = null;
  private inputLog: ReplayInputFrame[] = [];
  private startedAt = new Date().toISOString();
  private readonly options: ReplayRecorderOptions;

  constructor(options: ReplayRecorderOptions) {
    this.options = options;
  }

  start(state: GameState): void {
    this.initialState = structuredClone(state);
    this.inputLog = [];
    this.startedAt = new Date().toISOString();
  }

  recordFrame(frame: number, inputs: InputFrame[]): void {
    this.inputLog.push({ frame, inputs: structuredClone(inputs) });
  }

  finalize(matchId: string, finalState: GameState): ReplayRecord | null {
    if (!this.initialState) return null;
    return createReplayRecord({
      matchId,
      gameVersion: this.options.gameVersion,
      mode: this.options.mode,
      ruleset: this.options.ruleset,
      initialState: this.initialState,
      inputLog: this.inputLog,
      title: this.options.title ?? `${this.options.mode} Replay`,
    });
  }

  getInputLog(): ReplayInputFrame[] {
    return this.inputLog;
  }

  getInitialStateSerialized(): string | null {
    return this.initialState ? serializeState(this.initialState) : null;
  }

  getFinalHash(state: GameState): string {
    return hashState(state);
  }

  getStartedAt(): string {
    return this.startedAt;
  }
}
