import type { NetplayMessage, NetplayTransport } from "./transport.js";

export type WebSocketTransportConfig = {
  url: string;
  localPlayerId: number;
};

/** WebSocket transport stub — connect throws until relay server exists. */
export class WebSocketTransport implements NetplayTransport {
  readonly localPlayerId: number;
  private url: string;

  constructor(config: WebSocketTransportConfig) {
    this.localPlayerId = config.localPlayerId;
    this.url = config.url;
  }

  async connect(): Promise<void> {
    throw new Error(`WebSocket relay not deployed: ${this.url}`);
  }

  disconnect(): void {}

  send(_message: NetplayMessage): void {}

  poll(): NetplayMessage[] {
    return [];
  }
}
