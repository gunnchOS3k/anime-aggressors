import type { NetplayMessage, NetplayTransport } from "./transport.js";

export type LoopbackOptions = {
  latencyFrames?: number;
  jitterFrames?: number;
  dropRate?: number;
  seed?: number;
};

class LoopbackTransport implements NetplayTransport {
  readonly localPlayerId: number;
  private inbox: NetplayMessage[];
  private peerInbox: NetplayMessage[];
  private connected = false;
  private dropRate: number;
  private rng: () => number;

  constructor(
    playerId: number,
    inbox: NetplayMessage[],
    peerInbox: NetplayMessage[],
    options: LoopbackOptions,
  ) {
    this.localPlayerId = playerId;
    this.inbox = inbox;
    this.peerInbox = peerInbox;
    this.dropRate = options.dropRate ?? 0;
    this.rng = mulberry32(options.seed ?? 1);
  }

  async connect(): Promise<void> {
    this.connected = true;
    this.send({
      type: "handshake",
      playerId: this.localPlayerId,
      sessionId: "loopback",
      frame: 0,
    });
  }

  disconnect(): void {
    this.connected = false;
    this.inbox.length = 0;
  }

  send(message: NetplayMessage): void {
    if (!this.connected) return;
    if (this.rng() < this.dropRate) return;
    this.peerInbox.push(message);
  }

  poll(): NetplayMessage[] {
    return this.inbox.splice(0, this.inbox.length);
  }
}

export function createLoopbackPair(
  options: LoopbackOptions = {},
): [LoopbackTransport, LoopbackTransport] {
  const q0: NetplayMessage[] = [];
  const q1: NetplayMessage[] = [];
  return [
    new LoopbackTransport(0, q0, q1, options),
    new LoopbackTransport(1, q1, q0, options),
  ];
}

export function inputFromMessage(msg: NetplayMessage): import("@anime-aggressors/game-core").InputFrame | null {
  if (msg.type !== "input") return null;
  return msg.input;
}

function mulberry32(seed: number): () => number {
  let s = seed;
  return () => {
    s |= 0;
    s = (s + 0x6d2b79f5) | 0;
    let t = Math.imul(s ^ (s >>> 15), 1 | s);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export type { LoopbackTransport };
