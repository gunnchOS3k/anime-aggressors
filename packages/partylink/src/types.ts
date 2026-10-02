import type { TransportMode } from "./capacity.js";

export type PartyRole = "OWNER" | "DISPLAY_HOST" | "PLAYER" | "SPECTATOR";

export type SeatState =
  | "EMPTY"
  | "JOINING"
  | "CONNECTED"
  | "READY"
  | "DISCONNECTED_RECONNECTABLE"
  | "ELIMINATED_OR_FINISHED";

export type RoomPhase =
  | "lobby"
  | "fighter_select"
  | "ready_check"
  | "countdown"
  | "playing"
  | "results"
  | "closed";

export type AuthorityMode = "HOST_AUTHORITATIVE_PARTY" | "DETERMINISTIC_ROLLBACK";

/** Presentation-only; combat authority ignores body_variant. */
export type FighterBodyVariant = "male" | "female";

export type TeamAssignment =
  | { mode: "FFA" }
  | { mode: "2v2"; teamId: 0 | 1 }
  | { mode: "3v3"; teamId: 0 | 1 }
  | { mode: "4v4"; teamId: 0 | 1 }
  | { mode: "2v2v2v2"; teamId: 0 | 1 | 2 | 3 };

export type PlayerSeat = {
  seatIndex: number;
  state: SeatState;
  participantId: string | null;
  fighterId: string | null;
  /** Presentation-only dual-form body. Combat sim ignores this. */
  bodyVariant: FighterBodyVariant | null;
  displayName: string | null;
  team: TeamAssignment | null;
  identity: DuplicateFighterIdentity | null;
};

export type DuplicateFighterIdentity = {
  bodyVariant: FighterBodyVariant;
  paletteIndex: number;
  outlineColor: string;
  badgeLabel: string;
  hudColor: string;
  /** Small aura-ring / trim accent — not a full mesh palette swap. */
  auraRingColor: string;
  /** True when >2 seats share the same fighter_id (accent-only differentiation). */
  accentOnly: boolean;
  nameSuffix: string;
};

export type PartyParticipant = {
  id: string;
  role: PartyRole;
  displayName: string;
  token: string;
  seatIndex: number | null;
  connected: boolean;
  lastSeenMs: number;
};

export type RoomCapabilities = {
  maxPlayerSeats: number;
  maxSpectatorSeats: number;
  authorityMode: AuthorityMode;
  allowDuplicateFighters: boolean;
  transports: TransportMode[];
  partyModes: string[];
};

export type TransportCapabilities = {
  selected: TransportMode;
  available: TransportMode[];
  publicRelayDeployed: boolean;
};

export type ConnectionQuality = {
  participantId: string;
  rttMs: number | null;
  jitterMs: number | null;
  lossRatio: number;
  degraded: boolean;
};

export type PartyRoom = {
  code: string;
  sessionId: string;
  protocolVersion: string;
  phase: RoomPhase;
  createdAtMs: number;
  expiresAtMs: number;
  ownerId: string;
  displayHostId: string | null;
  seats: PlayerSeat[];
  participants: PartyParticipant[];
  spectators: PartyParticipant[];
  capabilities: RoomCapabilities;
  transport: TransportCapabilities;
  gameId: "anime-aggressors" | "pedestrian-pursuit";
};

export type JoinRequest = {
  code: string;
  displayName: string;
  role: "PLAYER" | "SPECTATOR";
  resumeToken?: string;
};

export type JoinResponse =
  | {
      ok: true;
      participant: PartyParticipant;
      room: PublicRoomView;
      qrPayload: string;
    }
  | { ok: false; reason: string };

export type ControllerInput = {
  participantId: string;
  token: string;
  seatIndex: number;
  sequence: number;
  tick: number;
  semantic: Record<string, unknown>;
  clientMs: number;
};

export type InputAck = {
  seatIndex: number;
  sequence: number;
  accepted: boolean;
  reason?: string;
};

export type PublicGameState = {
  sessionId: string;
  gameId: string;
  protocolVersion: string;
  phase: RoomPhase;
  hostTick: number;
  players: Array<{
    seatIndex: number;
    displayName: string;
    fighterId: string | null;
    bodyVariant?: FighterBodyVariant | null;
    stocks?: number;
    damage?: number;
    place?: number;
    lap?: number;
    eliminated: boolean;
    identity: DuplicateFighterIdentity | null;
  }>;
  world: Record<string, unknown>;
  events: Array<{ type: string; atTick: number; payload?: Record<string, unknown> }>;
  result: Record<string, unknown> | null;
};

export type SpectatorSubscription = {
  participantId: string;
  token: string;
  lastAckTick: number;
};

export type ReconnectRequest = {
  code: string;
  participantId: string;
  token: string;
};

export type PublicRoomView = {
  code: string;
  sessionId: string;
  phase: RoomPhase;
  seats: Array<{
    seatIndex: number;
    state: SeatState;
    displayName: string | null;
    fighterId: string | null;
    bodyVariant: FighterBodyVariant | null;
  }>;
  spectatorCount: number;
  maxPlayerSeats: number;
  maxSpectatorSeats: number;
  joinUrl: string;
  qrPayload: string;
};

export type PartyModeId =
  | "FFA"
  | "TEAMS_2V2"
  | "TEAMS_3V3"
  | "TEAMS_4V4"
  | "TEAMS_2V2V2V2";

export type CapacityMetrics = {
  playerCount: number;
  meanInputLatencyMs: number | null;
  p95InputLatencyMs: number | null;
  meanFrameMs: number | null;
  p95FrameMs: number | null;
  statePayloadBytes: number;
  bandwidthBytesPerSec: number | null;
  desyncCount: number;
  reconnectOk: boolean;
  cameraHudOk: boolean;
  pass: boolean;
};
