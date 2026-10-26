import {
  createInitialGameState,
  hashState,
  type GameConfig,
  type GameState,
  type InputFrame,
} from "@anime-aggressors/game-core";
import { RollbackSession, inputsEqual } from "@anime-aggressors/rollback";
import type { NetplayTransport } from "./transport.js";

export type NetplaySessionConfig = {
  gameConfig: GameConfig;
  localPlayerId: number;
};

export class NetplaySession {
  private rollback: RollbackSession;
  private frame = 0;
  private readonly historyFrames = 120;
  private readonly playerCount: number;
  private remoteInputs = new Map<number, Map<number, InputFrame>>();

  constructor(
    private transport: NetplayTransport,
    config: NetplaySessionConfig,
  ) {
    this.playerCount = config.gameConfig.playerCount;
    if (!Number.isInteger(this.playerCount) || this.playerCount < 2 ||
        config.localPlayerId !== transport.localPlayerId ||
        !Number.isInteger(config.localPlayerId) || config.localPlayerId < 0 ||
        config.localPlayerId >= this.playerCount) {
      throw new Error("Invalid netplay seat configuration");
    }
    const initial = createInitialGameState(config.gameConfig);
    this.rollback = new RollbackSession(initial, {
      snapshotInterval: 1,
      maxRollbackFrames: this.historyFrames,
      playerCount: config.gameConfig.playerCount,
    });
  }

  getState(): GameState {
    return this.rollback.getState();
  }

  getRollbackStats() { return this.rollback.getStats(); }

  /** Reconcile received inputs without advancing simulation or sending input.
   * Transport authentication remains the transport's responsibility. These
   * checks establish seat/frame consistency, not authenticated online play.
   */
  pumpRemoteInputs(): GameState {
    const messages = this.transport.poll();
    for (const message of messages) {
      if (message.type !== "input") continue;
      const input = message.input;
      if (!input || message.frame !== input.frame || message.playerId !== input.playerId ||
          !Number.isInteger(message.frame) || message.frame < 0 ||
          !Number.isInteger(message.playerId) || message.playerId < 0 ||
          message.playerId >= this.playerCount || message.playerId === this.transport.localPlayerId) {
        throw new Error("Remote input seat/frame mismatch");
      }
      if (message.frame < this.frame - this.historyFrames) {
        throw new Error("Remote input outside rollback history: state resynchronization required");
      }
      if (message.frame > this.frame + this.historyFrames) {
        throw new Error("Remote input exceeds future frame window");
      }
      const normalized = validateInput(input);
      let row = this.remoteInputs.get(message.frame);
      const previous = row?.get(message.playerId);
      if (previous) {
        if (!inputsEqual(previous, normalized)) throw new Error("Conflicting confirmed remote input");
        continue;
      }
      if (!row) { row = new Map(); this.remoteInputs.set(message.frame, row); }
      row.set(message.playerId, normalized);
      if (message.frame < this.frame) {
        this.rollback.confirmInputs(message.frame, [normalized]);
      }
    }
    this.pruneRemoteInputs();
    return this.getState();
  }

  advanceLocal(inputs: InputFrame[]): GameState {
    this.pumpRemoteInputs();
    if (inputs.length > 1 || inputs.some(input =>
      input.playerId !== this.transport.localPlayerId || input.frame !== this.frame)) {
      throw new Error("Local input must identify this seat and simulation frame");
    }
    const local = validateInput(inputs[0] ?? emptyInput(this.frame, this.transport.localPlayerId));
    const row = this.remoteInputs.get(this.frame);

    const frameInputs: InputFrame[] = [];
    const confirmed: boolean[] = [];
    for (let p = 0; p < this.playerCount; p++) {
      const input = p === local.playerId ? local : row?.get(p) ?? emptyInput(this.frame, p);
      frameInputs.push(input);
      confirmed.push(p === local.playerId || !!row?.has(p));
    }

    this.rollback.advanceFrame(frameInputs, confirmed);
    // The wire frame is the input's actual simulation frame, never N+1.
    this.transport.send({ type: "input", frame: this.frame, playerId: local.playerId, input: { ...local } });
    this.frame += 1;
    this.pruneRemoteInputs();
    return this.getState();
  }

  private pruneRemoteInputs(): void {
    for (const frame of this.remoteInputs.keys()) {
      if (frame < this.frame - this.historyFrames) this.remoteInputs.delete(frame);
    }
  }
}

function validateInput(input: InputFrame): InputFrame {
  const normalized = emptyInput(input.frame, input.playerId);
  for (const key of ["left", "right", "up", "down", "jump", "attack", "special", "shield", "dodge", "grab"] as const) {
    if (typeof input[key] !== "boolean") throw new Error("Invalid input button value");
    normalized[key] = input[key];
  }
  if (input.auraCharge !== undefined && typeof input.auraCharge !== "boolean") throw new Error("Invalid aura input");
  if (input.auraCharge !== undefined) normalized.auraCharge = input.auraCharge;
  if (input.wearableGesture !== undefined) {
    if (!["swipeL", "swipeR", "swipeU", "swipeD", "thrust", "tap", "doubleTap", "block", "shake"].includes(input.wearableGesture)) {
      throw new Error("Invalid wearable input");
    }
    normalized.wearableGesture = input.wearableGesture;
  }
  return normalized;
}

function emptyInput(frame: number, playerId: number): InputFrame {
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

export function simulateLoopbackPeers(
  frames: number,
  makeInput: (frame: number, playerId: number) => InputFrame,
  transports: [NetplayTransport, NetplayTransport],
  config: GameConfig,
): { hash0: string; hash1: string; match: boolean } {
  const s0 = new NetplaySession(transports[0], { gameConfig: config, localPlayerId: 0 });
  const s1 = new NetplaySession(transports[1], { gameConfig: config, localPlayerId: 1 });

  for (let f = 0; f < frames; f++) {
    s0.advanceLocal([makeInput(f, 0)]);
    s1.advanceLocal([makeInput(f, 1)]);
  }
  // Drain the last send at the SAME simulation tip; do not add a fake game tick.
  s0.pumpRemoteInputs();
  s1.pumpRemoteInputs();

  const hash0 = hashState(s0.getState());
  const hash1 = hashState(s1.getState());
  return { hash0, hash1, match: hash0 === hash1 };
}
