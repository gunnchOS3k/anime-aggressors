import type { InputFrame } from "@anime-aggressors/game-core";

export type NetplayMessageType = "handshake" | "input" | "ping";

export type HandshakeMessage = {
  type: "handshake";
  playerId: number;
  sessionId: string;
  frame: number;
};

export type RemoteInputMessage = {
  type: "input";
  frame: number;
  playerId: number;
  input: InputFrame;
};

export type PingMessage = {
  type: "ping";
  frame: number;
  t: number;
};

export type NetplayMessage = HandshakeMessage | RemoteInputMessage | PingMessage;

export interface NetplayTransport {
  readonly localPlayerId: number;
  connect(): Promise<void>;
  disconnect(): void;
  send(message: NetplayMessage): void;
  poll(): NetplayMessage[];
}
