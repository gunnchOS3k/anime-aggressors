import {
  createInitialGameState,
  hashState,
  type GameConfig,
  type GameState,
  type InputFrame,
} from "@anime-aggressors/game-core";
import { RollbackSession } from "@anime-aggressors/rollback";
import type { NetplayTransport } from "./transport.js";
import { inputFromMessage } from "./localLoopbackTransport.js";

export type NetplaySessionConfig = {
  gameConfig: GameConfig;
  localPlayerId: number;
};

export class NetplaySession {
  private rollback: RollbackSession;
  private state: GameState;
  private frame = 0;

  constructor(
    private transport: NetplayTransport,
    config: NetplaySessionConfig,
  ) {
    this.state = createInitialGameState(config.gameConfig);
    this.rollback = new RollbackSession(this.state, {
      snapshotInterval: 1,
      maxRollbackFrames: 120,
      playerCount: config.gameConfig.playerCount,
    });
  }

  getState(): GameState {
    return this.state;
  }

  advanceLocal(inputs: InputFrame[]): GameState {
    const remote = this.transport.poll();
    const merged = [...inputs];
    for (const msg of remote) {
      const input = inputFromMessage(msg);
      if (input) merged.push(input);
    }

    const byPlayer = new Map<number, InputFrame>();
    for (const i of merged) {
      byPlayer.set(i.playerId, i);
    }

    const frameInputs: InputFrame[] = [];
    const confirmed: boolean[] = [];
    for (let p = 0; p < 2; p++) {
      const input = byPlayer.get(p) ?? emptyInput(this.frame, p);
      frameInputs.push(input);
      confirmed.push(byPlayer.has(p));
    }

    this.state = this.rollback.advanceFrame(frameInputs, confirmed);
    this.frame += 1;

    const local = frameInputs.find((i) => i.playerId === this.transport.localPlayerId);
    if (local) {
      this.transport.send({ type: "input", frame: this.frame, playerId: local.playerId, input: local });
    }

    return this.state;
  }
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

  const hash0 = hashState(s0.getState());
  const hash1 = hashState(s1.getState());
  return { hash0, hash1, match: hash0 === hash1 };
}
