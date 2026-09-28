/** PartyLink V2 capacity — player seats vs spectators are separate. */
export const PROTOCOL_VERSION = "partylink.v1";

export const MIN_PLAYER_SEATS = 2;
export const MAX_PLAYER_SEATS = 8;
/** Spectators never consume a player seat. */
export const MAX_SPECTATOR_SEATS = 32;

export const CAPACITY_LADDER = [2, 4, 6, 8] as const;
export type CapacityTier = (typeof CAPACITY_LADDER)[number];

export const ROOM_TTL_MS = 2 * 60 * 60 * 1000;
export const INPUT_RATE_LIMIT_PER_SEC = 120;
export const JOIN_RATE_LIMIT_PER_MIN = 30;

export type TransportMode =
  | "LOCAL_DIRECT"
  | "LAN_WEBSOCKET"
  | "WEBRTC_DATA"
  | "HOSTED_WSS_RELAY"
  | "NATIVE_NETPLAY";

/** V1 required: same-room / LAN. Public relay stays false until deployed. */
export const V1_TRANSPORTS: TransportMode[] = ["LOCAL_DIRECT", "LAN_WEBSOCKET"];

export function isValidPlayerCount(n: number): n is CapacityTier | 3 | 5 | 7 {
  return Number.isInteger(n) && n >= MIN_PLAYER_SEATS && n <= MAX_PLAYER_SEATS;
}

export function assertCapacityTier(n: number): CapacityTier {
  if (!(CAPACITY_LADDER as readonly number[]).includes(n)) {
    throw new Error(`capacity tier must be one of ${CAPACITY_LADDER.join(",")}; got ${n}`);
  }
  return n as CapacityTier;
}
