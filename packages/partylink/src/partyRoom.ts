import {
  INPUT_RATE_LIMIT_PER_SEC,
  JOIN_RATE_LIMIT_PER_MIN,
  MAX_PLAYER_SEATS,
  MAX_SPECTATOR_SEATS,
  MIN_PLAYER_SEATS,
  PROTOCOL_VERSION,
  ROOM_TTL_MS,
  V1_TRANSPORTS,
  isValidPlayerCount,
} from "./capacity.js";
import {
  buildJoinQrPayload,
  createParticipantToken,
  createSessionId,
  generateRoomCode,
  sanitizePlayerName,
} from "./identity.js";
import { assignDuplicateIdentity } from "./duplicateIdentity.js";
import type {
  ControllerInput,
  InputAck,
  JoinRequest,
  JoinResponse,
  PartyParticipant,
  PartyRoom,
  PlayerSeat,
  PublicGameState,
  PublicRoomView,
  ReconnectRequest,
  RoomPhase,
} from "./types.js";

export type CreateRoomOptions = {
  gameId: "anime-aggressors" | "pedestrian-pursuit";
  ownerDisplayName: string;
  maxPlayerSeats?: number;
  maxSpectatorSeats?: number;
  nowMs?: number;
};

function emptySeats(n: number): PlayerSeat[] {
  return Array.from({ length: n }, (_, seatIndex) => ({
    seatIndex,
    state: "EMPTY" as const,
    participantId: null,
    fighterId: null,
    bodyVariant: null,
    displayName: null,
    team: null,
    identity: null,
  }));
}

function publicView(room: PartyRoom): PublicRoomView {
  const qrPayload = buildJoinQrPayload({
    code: room.code,
    gameId: room.gameId,
    role: "PLAYER",
  });
  return {
    code: room.code,
    sessionId: room.sessionId,
    phase: room.phase,
    seats: room.seats.map((s) => ({
      seatIndex: s.seatIndex,
      state: s.state,
      displayName: s.displayName,
      fighterId: s.fighterId,
      bodyVariant: s.bodyVariant,
    })),
    spectatorCount: room.spectators.length,
    maxPlayerSeats: room.capabilities.maxPlayerSeats,
    maxSpectatorSeats: room.capabilities.maxSpectatorSeats,
    joinUrl: qrPayload,
    qrPayload,
  };
}

export class PartyRoomSession {
  readonly room: PartyRoom;
  private joinTimestamps: number[] = [];
  private inputTimestamps = new Map<string, number[]>();
  private lastSequence = new Map<string, number>();
  private hostTick = 0;
  private result: Record<string, unknown> | null = null;

  constructor(opts: CreateRoomOptions) {
    const maxPlayers = opts.maxPlayerSeats ?? MAX_PLAYER_SEATS;
    if (!isValidPlayerCount(maxPlayers)) {
      throw new Error(`maxPlayerSeats must be ${MIN_PLAYER_SEATS}..${MAX_PLAYER_SEATS}`);
    }
    const maxSpectators = opts.maxSpectatorSeats ?? MAX_SPECTATOR_SEATS;
    const now = opts.nowMs ?? Date.now();
    const ownerId = `p_${createParticipantToken().slice(0, 12)}`;
    const ownerToken = createParticipantToken();
    const owner: PartyParticipant = {
      id: ownerId,
      role: "OWNER",
      displayName: sanitizePlayerName(opts.ownerDisplayName),
      token: ownerToken,
      seatIndex: null,
      connected: true,
      lastSeenMs: now,
    };

    this.room = {
      code: generateRoomCode(),
      sessionId: createSessionId(),
      protocolVersion: PROTOCOL_VERSION,
      phase: "lobby",
      createdAtMs: now,
      expiresAtMs: now + ROOM_TTL_MS,
      ownerId,
      displayHostId: ownerId,
      seats: emptySeats(maxPlayers),
      participants: [owner],
      spectators: [],
      capabilities: {
        maxPlayerSeats: maxPlayers,
        maxSpectatorSeats: maxSpectators,
        authorityMode: "HOST_AUTHORITATIVE_PARTY",
        allowDuplicateFighters: true,
        transports: [...V1_TRANSPORTS],
        partyModes: ["FFA", "TEAMS_2V2", "TEAMS_3V3", "TEAMS_4V4", "TEAMS_2V2V2V2"],
      },
      transport: {
        selected: "LOCAL_DIRECT",
        available: [...V1_TRANSPORTS],
        publicRelayDeployed: false,
      },
      gameId: opts.gameId,
    };
  }

  getPublicRoom(): PublicRoomView {
    return publicView(this.room);
  }

  isExpired(nowMs = Date.now()): boolean {
    return nowMs > this.room.expiresAtMs || this.room.phase === "closed";
  }

  private rateLimitJoin(nowMs: number): boolean {
    this.joinTimestamps = this.joinTimestamps.filter((t) => nowMs - t < 60_000);
    if (this.joinTimestamps.length >= JOIN_RATE_LIMIT_PER_MIN) return false;
    this.joinTimestamps.push(nowMs);
    return true;
  }

  join(req: JoinRequest, nowMs = Date.now()): JoinResponse {
    if (this.isExpired(nowMs)) return { ok: false, reason: "room_expired" };
    if (req.code.toUpperCase() !== this.room.code) return { ok: false, reason: "bad_code" };
    if (!this.rateLimitJoin(nowMs)) return { ok: false, reason: "join_rate_limited" };

    if (req.resumeToken) {
      const existing =
        this.room.participants.find((p) => p.token === req.resumeToken) ??
        this.room.spectators.find((p) => p.token === req.resumeToken);
      if (!existing) return { ok: false, reason: "bad_resume_token" };
      existing.connected = true;
      existing.lastSeenMs = nowMs;
      if (existing.seatIndex != null) {
        const seat = this.room.seats[existing.seatIndex];
        if (seat && seat.state === "DISCONNECTED_RECONNECTABLE") {
          seat.state = "CONNECTED";
        }
      }
      return { ok: true, participant: existing, room: publicView(this.room), qrPayload: publicView(this.room).qrPayload };
    }

    if (req.role === "SPECTATOR") {
      if (this.room.spectators.length >= this.room.capabilities.maxSpectatorSeats) {
        return { ok: false, reason: "spectator_full" };
      }
      const spectator: PartyParticipant = {
        id: `s_${createParticipantToken().slice(0, 12)}`,
        role: "SPECTATOR",
        displayName: sanitizePlayerName(req.displayName),
        token: createParticipantToken(),
        seatIndex: null,
        connected: true,
        lastSeenMs: nowMs,
      };
      this.room.spectators.push(spectator);
      return {
        ok: true,
        participant: spectator,
        room: publicView(this.room),
        qrPayload: buildJoinQrPayload({ code: this.room.code, gameId: this.room.gameId, role: "SPECTATOR" }),
      };
    }

    const empty = this.room.seats.find((s) => s.state === "EMPTY");
    if (!empty) return { ok: false, reason: "player_seats_full" };

    const player: PartyParticipant = {
      id: `p_${createParticipantToken().slice(0, 12)}`,
      role: "PLAYER",
      displayName: sanitizePlayerName(req.displayName),
      token: createParticipantToken(),
      seatIndex: empty.seatIndex,
      connected: true,
      lastSeenMs: nowMs,
    };
    empty.state = "CONNECTED";
    empty.participantId = player.id;
    empty.displayName = player.displayName;
    this.room.participants.push(player);
    return {
      ok: true,
      participant: player,
      room: publicView(this.room),
      qrPayload: publicView(this.room).qrPayload,
    };
  }

  /** Owner may also claim a player seat (DISPLAY_HOST + PLAYER). */
  claimOwnerSeat(nowMs = Date.now()): JoinResponse {
    return this.join(
      {
        code: this.room.code,
        displayName: this.room.participants.find((p) => p.id === this.room.ownerId)?.displayName ?? "Host",
        role: "PLAYER",
      },
      nowMs,
    );
  }

  setFighter(
    participantId: string,
    token: string,
    fighterId: string,
    preferredBodyVariant?: import("./types.js").FighterBodyVariant | null,
  ): { ok: boolean; reason?: string } {
    const p = this.room.participants.find((x) => x.id === participantId && x.token === token);
    if (!p || p.seatIndex == null) return { ok: false, reason: "not_seated_player" };
    const seat = this.room.seats[p.seatIndex]!;
    seat.fighterId = fighterId;
    seat.identity = assignDuplicateIdentity(
      fighterId,
      seat.seatIndex,
      this.room.seats.map((s) => ({
        fighterId: s.fighterId,
        seatIndex: s.seatIndex,
        bodyVariant: s.bodyVariant,
      })),
      preferredBodyVariant,
    );
    seat.bodyVariant = seat.identity.bodyVariant;
    return { ok: true };
  }

  setTeam(
    participantId: string,
    token: string,
    team: PlayerSeat["team"],
  ): { ok: boolean; reason?: string } {
    const p = this.room.participants.find((x) => x.id === participantId && x.token === token);
    if (!p || p.seatIndex == null) return { ok: false, reason: "not_seated_player" };
    this.room.seats[p.seatIndex]!.team = team;
    return { ok: true };
  }

  setReady(participantId: string, token: string, ready: boolean): { ok: boolean; reason?: string } {
    const p = this.room.participants.find((x) => x.id === participantId && x.token === token);
    if (!p || p.seatIndex == null) return { ok: false, reason: "not_seated_player" };
    const seat = this.room.seats[p.seatIndex]!;
    if (seat.state !== "CONNECTED" && seat.state !== "READY") return { ok: false, reason: "bad_seat_state" };
    seat.state = ready ? "READY" : "CONNECTED";
    return { ok: true };
  }

  startMatch(ownerToken: string): { ok: boolean; reason?: string } {
    const owner = this.room.participants.find((p) => p.id === this.room.ownerId);
    if (!owner || owner.token !== ownerToken) return { ok: false, reason: "owner_only" };
    const seated = this.room.seats.filter((s) => s.state === "READY" || s.state === "CONNECTED");
    const ready = this.room.seats.filter((s) => s.state === "READY");
    if (ready.length < MIN_PLAYER_SEATS) return { ok: false, reason: "need_min_ready" };
    if (ready.length !== seated.length) return { ok: false, reason: "not_all_ready" };
    this.room.phase = "playing";
    this.hostTick = 0;
    this.result = null;
    return { ok: true };
  }

  disconnect(participantId: string, nowMs = Date.now()): void {
    const p =
      this.room.participants.find((x) => x.id === participantId) ??
      this.room.spectators.find((x) => x.id === participantId);
    if (!p) return;
    p.connected = false;
    p.lastSeenMs = nowMs;
    for (const seat of this.room.seats) {
      if (seat.participantId !== participantId) continue;
      if (seat.state === "CONNECTED" || seat.state === "READY" || seat.state === "JOINING") {
        seat.state = "DISCONNECTED_RECONNECTABLE";
      }
    }
  }

  reconnect(req: ReconnectRequest, nowMs = Date.now()): JoinResponse {
    if (this.isExpired(nowMs)) return { ok: false, reason: "room_expired" };
    if (req.code.toUpperCase() !== this.room.code) return { ok: false, reason: "bad_code" };
    return this.join(
      {
        code: req.code,
        displayName: "rejoin",
        role: "PLAYER",
        resumeToken: req.token,
      },
      nowMs,
    );
  }

  submitInput(input: ControllerInput, nowMs = Date.now()): InputAck {
    if (this.room.phase !== "playing") {
      return { seatIndex: input.seatIndex, sequence: input.sequence, accepted: false, reason: "not_playing" };
    }

    const spectator = this.room.spectators.find((s) => s.id === input.participantId);
    if (spectator) {
      return { seatIndex: input.seatIndex, sequence: input.sequence, accepted: false, reason: "spectator_input_rejected" };
    }

    const p = this.room.participants.find((x) => x.id === input.participantId && x.token === input.token);
    if (!p || p.role === "SPECTATOR") {
      return { seatIndex: input.seatIndex, sequence: input.sequence, accepted: false, reason: "authz_failed" };
    }
    if (p.seatIndex !== input.seatIndex) {
      return { seatIndex: input.seatIndex, sequence: input.sequence, accepted: false, reason: "wrong_seat_input_rejected" };
    }

    const key = p.id;
    const stamps = (this.inputTimestamps.get(key) ?? []).filter((t) => nowMs - t < 1000);
    if (stamps.length >= INPUT_RATE_LIMIT_PER_SEC) {
      this.inputTimestamps.set(key, stamps);
      return { seatIndex: input.seatIndex, sequence: input.sequence, accepted: false, reason: "input_rate_limited" };
    }
    stamps.push(nowMs);
    this.inputTimestamps.set(key, stamps);

    const last = this.lastSequence.get(key) ?? -1;
    if (input.sequence <= last) {
      return { seatIndex: input.seatIndex, sequence: input.sequence, accepted: false, reason: "stale_sequence" };
    }
    this.lastSequence.set(key, input.sequence);
    this.hostTick = Math.max(this.hostTick, input.tick);
    return { seatIndex: input.seatIndex, sequence: input.sequence, accepted: true };
  }

  advanceHostTick(): number {
    this.hostTick += 1;
    return this.hostTick;
  }

  setPhase(phase: RoomPhase): void {
    this.room.phase = phase;
  }

  setResult(result: Record<string, unknown>): void {
    this.result = result;
    this.room.phase = "results";
  }

  rematch(ownerToken: string): { ok: boolean; reason?: string } {
    const owner = this.room.participants.find((p) => p.id === this.room.ownerId);
    if (!owner || owner.token !== ownerToken) return { ok: false, reason: "owner_only" };
    for (const seat of this.room.seats) {
      if (seat.participantId) seat.state = "CONNECTED";
    }
    this.result = null;
    this.hostTick = 0;
    this.room.phase = "lobby";
    return { ok: true };
  }

  publicGameState(): PublicGameState {
    return {
      sessionId: this.room.sessionId,
      gameId: this.room.gameId,
      protocolVersion: this.room.protocolVersion,
      phase: this.room.phase,
      hostTick: this.hostTick,
      players: this.room.seats
        .filter((s) => s.participantId)
        .map((s) => ({
          seatIndex: s.seatIndex,
          displayName: s.displayName ?? `P${s.seatIndex + 1}`,
          fighterId: s.fighterId,
          eliminated: s.state === "ELIMINATED_OR_FINISHED",
          identity: s.identity,
        })),
      world: {},
      events: [],
      result: this.result,
    };
  }

  /** Spectators never occupy player seats — capacity checks are independent. */
  capacitySnapshot(): {
    playerSeatsUsed: number;
    playerSeatsMax: number;
    spectatorSeatsUsed: number;
    spectatorSeatsMax: number;
    spectatorSeparate: boolean;
  } {
    return {
      playerSeatsUsed: this.room.seats.filter((s) => s.state !== "EMPTY").length,
      playerSeatsMax: this.room.capabilities.maxPlayerSeats,
      spectatorSeatsUsed: this.room.spectators.length,
      spectatorSeatsMax: this.room.capabilities.maxSpectatorSeats,
      spectatorSeparate: true,
    };
  }
}
