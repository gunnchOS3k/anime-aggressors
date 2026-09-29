import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  CAPACITY_LADDER,
  MAX_PLAYER_SEATS,
  MAX_SPECTATOR_SEATS,
  MIN_PLAYER_SEATS,
  PartyRoomSession,
  HostAuthoritativePartySim,
  partyGameConfig,
  assignDuplicateIdentity,
  identityPass,
  frameAllFighters,
} from "../src/index.js";

describe("PartyLink capacity schema", () => {
  it("keeps player seats and spectator capacity separate", () => {
    assert.equal(MIN_PLAYER_SEATS, 2);
    assert.equal(MAX_PLAYER_SEATS, 8);
    assert.ok(MAX_SPECTATOR_SEATS > MAX_PLAYER_SEATS);

    const room = new PartyRoomSession({
      gameId: "anime-aggressors",
      ownerDisplayName: "Host",
      maxPlayerSeats: 8,
    });

    // Fill all 8 player seats
    for (let i = 0; i < 8; i++) {
      const res = room.join({ code: room.room.code, displayName: `P${i}`, role: "PLAYER" });
      assert.equal(res.ok, true, `player ${i}`);
    }
    const full = room.join({ code: room.room.code, displayName: "P9", role: "PLAYER" });
    assert.equal(full.ok, false);
    if (!full.ok) assert.equal(full.reason, "player_seats_full");

    // Spectator is still allowed — never consumes player seat 9
    const spec = room.join({ code: room.room.code, displayName: "Watcher", role: "SPECTATOR" });
    assert.equal(spec.ok, true);
    const snap = room.capacitySnapshot();
    assert.equal(snap.playerSeatsUsed, 8);
    assert.equal(snap.spectatorSeatsUsed, 1);
    assert.equal(snap.spectatorSeparate, true);
  });
});

describe("PartyLink authz", () => {
  it("rejects spectator gameplay input and wrong-seat input", () => {
    const room = new PartyRoomSession({
      gameId: "anime-aggressors",
      ownerDisplayName: "Host",
      maxPlayerSeats: 4,
    });
    const p0 = room.join({ code: room.room.code, displayName: "A", role: "PLAYER" });
    const p1 = room.join({ code: room.room.code, displayName: "B", role: "PLAYER" });
    const spec = room.join({ code: room.room.code, displayName: "S", role: "SPECTATOR" });
    assert.ok(p0.ok && p1.ok && spec.ok);
    if (!p0.ok || !p1.ok || !spec.ok) return;

    for (const p of [p0.participant, p1.participant]) {
      room.setReady(p.id, p.token, true);
    }
    const owner = room.room.participants.find((x) => x.id === room.room.ownerId)!;
    // Owner is not seated; mark seated players ready already — start needs READY seats.
    // Claim owner is separate; start with the two ready players.
    // Force start by ensuring READY count >= 2:
    assert.equal(room.startMatch(owner.token).ok, true);

    const wrongSeat = room.submitInput({
      participantId: p0.participant.id,
      token: p0.participant.token,
      seatIndex: p1.participant.seatIndex!,
      sequence: 1,
      tick: 1,
      semantic: { left: true },
      clientMs: Date.now(),
    });
    assert.equal(wrongSeat.accepted, false);
    assert.equal(wrongSeat.reason, "wrong_seat_input_rejected");

    const specInput = room.submitInput({
      participantId: spec.participant.id,
      token: spec.participant.token,
      seatIndex: 0,
      sequence: 1,
      tick: 1,
      semantic: { attack: true },
      clientMs: Date.now(),
    });
    assert.equal(specInput.accepted, false);
    assert.equal(specInput.reason, "spectator_input_rejected");

    const ok = room.submitInput({
      participantId: p0.participant.id,
      token: p0.participant.token,
      seatIndex: p0.participant.seatIndex!,
      sequence: 1,
      tick: 1,
      semantic: { left: true },
      clientMs: Date.now(),
    });
    assert.equal(ok.accepted, true);
  });

  it("supports reconnect after disconnect", () => {
    const room = new PartyRoomSession({
      gameId: "anime-aggressors",
      ownerDisplayName: "Host",
      maxPlayerSeats: 2,
    });
    const p0 = room.join({ code: room.room.code, displayName: "A", role: "PLAYER" });
    assert.ok(p0.ok);
    if (!p0.ok) return;
    room.disconnect(p0.participant.id);
    const seat = room.room.seats[p0.participant.seatIndex!]!;
    assert.equal(seat.state, "DISCONNECTED_RECONNECTABLE");
    const back = room.reconnect({
      code: room.room.code,
      participantId: p0.participant.id,
      token: p0.participant.token,
    });
    assert.equal(back.ok, true);
    assert.equal(room.room.seats[p0.participant.seatIndex!]!.state, "CONNECTED");
  });
});

describe("8P capacity ladder (Anime)", () => {
  for (const n of CAPACITY_LADDER) {
    it(`HOST_AUTHORITATIVE_PARTY ${n}P`, () => {
      const sim = new HostAuthoritativePartySim(partyGameConfig(n, 7));
      const latencies: number[] = [];
      for (let f = 0; f < 30; f++) {
        const inputs = Array.from({ length: n }, (_, seat) => ({
          seatIndex: seat,
          sequence: f + 1,
          frame: {
            frame: f,
            playerId: seat,
            left: seat % 2 === 0,
            right: seat % 2 === 1,
            up: false,
            down: false,
            jump: false,
            attack: f === 10 && seat === 0,
            special: false,
            shield: false,
            dodge: false,
            grab: false,
          },
        }));
        latencies.push(2 + (seatNoise(seatSeed(n, f)) % 8));
        sim.advance(inputs, [latencies[latencies.length - 1]!]);
      }
      const payload = JSON.stringify(sim.getState()).length;
      const m = sim.metrics({ reconnectOk: true, statePayloadBytes: payload });
      assert.equal(m.playerCount, n);
      assert.equal(m.pass, true);
      assert.equal(m.cameraHudOk, true);
      assert.equal(m.desyncCount, 0);
      assert.ok(m.p95FrameMs === null || m.p95FrameMs < 50);
      assert.equal(sim.hudSlots().length, n);
      assert.ok(sim.publicHash().length > 0);
    });
  }
});

describe("duplicate fighter identity + arena camera", () => {
  it("assigns distinct palette/outline/badge for duplicate fighters", () => {
    const built: ReturnType<typeof assignDuplicateIdentity>[] = [];
    for (let i = 0; i < 3; i++) {
      built.push(
        assignDuplicateIdentity(
          "ember",
          i,
          built.map((b, j) => ({
            fighterId: "ember",
            seatIndex: j,
            bodyVariant: b.bodyVariant,
          })),
        ),
      );
    }
    assert.equal(identityPass(built), true);
    assert.notEqual(built[0]!.badgeLabel, built[1]!.badgeLabel);
    assert.equal(built[0]!.bodyVariant, "male");
    assert.equal(built[1]!.bodyVariant, "female");
    assert.equal(built[2]!.accentOnly, true);
  });

  it("frames all active fighters with bounded zoom", () => {
    const frame = frameAllFighters(
      Array.from({ length: 8 }, (_, i) => ({
        seatIndex: i,
        x: 100 + i * 80,
        y: 400 + (i % 2) * 40,
        active: true,
      })),
    );
    assert.ok(frame.zoom >= 0.45 && frame.zoom <= 1.25);
  });
});

function seatSeed(n: number, f: number): number {
  return n * 1000 + f;
}
function seatNoise(seed: number): number {
  return (seed * 1103515245 + 12345) & 0x7fffffff;
}
