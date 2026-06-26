import {
  deserializeState,
  simulateFrame,
  type GameState,
  type ReplayRecord,
} from "@anime-aggressors/game-core";

export type ReplayPlaybackSpeed = 0.5 | 1 | 2;

export class ReplayPlayer {
  private state: GameState;
  private frameIndex = 0;
  private playing = false;
  private speed: ReplayPlaybackSpeed = 1;
  private rafId = 0;
  private lastTime = 0;
  private accumulator = 0;
  private readonly fixedDt = 1 / 60;
  private readonly record: ReplayRecord;
  private onFrame: (state: GameState, frame: number) => void;
  private onComplete: () => void;

  constructor(
    record: ReplayRecord,
    onFrame: (state: GameState, frame: number) => void,
    onComplete: () => void,
  ) {
    this.record = record;
    this.state = deserializeState(record.initialStateSerialized) as GameState;
    this.onFrame = onFrame;
    this.onComplete = onComplete;
  }

  getRecord(): ReplayRecord {
    return this.record;
  }

  getState(): GameState {
    return this.state;
  }

  getFrameIndex(): number {
    return this.frameIndex;
  }

  isPlaying(): boolean {
    return this.playing;
  }

  getSpeed(): ReplayPlaybackSpeed {
    return this.speed;
  }

  setSpeed(speed: ReplayPlaybackSpeed): void {
    this.speed = speed;
  }

  play(): void {
    if (this.playing) return;
    this.playing = true;
    this.lastTime = performance.now();
    this.accumulator = 0;
    this.loop(this.lastTime);
  }

  pause(): void {
    this.playing = false;
    cancelAnimationFrame(this.rafId);
  }

  stepForward(): void {
    this.advanceOneFrame();
  }

  seekToStart(): void {
    this.pause();
    this.state = deserializeState(this.record.initialStateSerialized) as GameState;
    this.frameIndex = 0;
    this.onFrame(this.state, 0);
  }

  private loop(now: number): void {
    if (!this.playing) return;
    const elapsed = Math.min((now - this.lastTime) / 1000, 0.1);
    this.lastTime = now;
    this.accumulator += elapsed * this.speed;

    while (this.accumulator >= this.fixedDt) {
      if (!this.advanceOneFrame()) {
        this.playing = false;
        this.onComplete();
        return;
      }
      this.accumulator -= this.fixedDt;
    }

    this.rafId = requestAnimationFrame((t) => this.loop(t));
  }

  private advanceOneFrame(): boolean {
    if (this.frameIndex >= this.record.inputLog.length) return false;
    const entry = this.record.inputLog[this.frameIndex];
    this.state = simulateFrame(this.state, entry.inputs);
    this.frameIndex += 1;
    this.onFrame(this.state, this.frameIndex);
    return this.frameIndex < this.record.inputLog.length;
  }

  dispose(): void {
    this.pause();
  }
}
