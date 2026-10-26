import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { startLanPartyHost, type LanHostHandle } from "../src/lanHost.js";
import { INPUT_RATE_LIMIT_PER_SEC } from "../src/capacity.js";

async function post(host: LanHostHandle, path: string, body: unknown) {
  const response = await fetch(`${host.url}${path}`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
  return { status: response.status, body: await response.json() };
}

async function readyHost() {
  const host = await startLanPartyHost({
    gameId: "anime-aggressors",
    ownerDisplayName: "Host",
    host: "127.0.0.1",
    maxPlayerSeats: 2,
  });
  try {
    const players = [];
    for (let i = 0; i < 2; i++) {
      const joined = await post(host, "/join", {
        code: host.session.room.code, displayName: `Player ${i + 1}`, role: "PLAYER",
      });
      assert.equal(joined.body.ok, true);
      const player = joined.body.participant;
      players.push(player);
      const ready = await post(host, "/ready", {
        participantId: player.id, token: player.token, ready: true,
      });
      assert.equal(ready.body.ok, true);
    }
    const owner = host.session.room.participants.find((p) => p.id === host.session.room.ownerId)!;
    return { host, players, owner };
  } catch (error) {
    await host.close();
    throw error;
  }
}

describe("LAN match ownership and rematch input lifetime", () => {
  for (const credentials of ["missing", "wrong", "player", "spectator"] as const) {
    it(`rejects ${credentials} start credentials without changing lobby setup`, async () => {
      const { host, players } = await readyHost();
      try {
        const spectator = await post(host, "/join", {
          code: host.session.room.code, displayName: "Viewer", role: "SPECTATOR",
        });
        const tokens = { wrong: "not-the-owner", player: players[0].token, spectator: spectator.body.participant.token };
        const before = JSON.stringify(host.session.getPublicRoom());
        const request = credentials === "missing" ? {} : { ownerToken: tokens[credentials] };
        const response = await post(host, "/start", { ...request, teamMode: "2v2" });
        assert.equal(JSON.stringify(host.session.getPublicRoom()), before);
        assert.equal(host.teamMode, "FFA");
        assert.equal(host.sim, null);
        assert.ok(host.session.room.seats.every((seat) => seat.team === null));
        assert.equal(response.status, 403);
        assert.equal(response.body.reason, "owner_only");
      } finally { await host.close(); }
    });
  }

  it("unauthorized rematch preserves the live simulation and queued player inputs", async () => {
    const { host, players, owner } = await readyHost();
    try {
      assert.equal((await post(host, "/start", { ownerToken: owner.token })).body.ok, true);
      host.tick();
      const sim = host.sim!;
      const frame = sim.getFrame();
      const player = players[0];
      const input = { participantId: player.id, token: player.token, seatIndex: player.seatIndex,
        sequence: 30, tick: 1, semantic: { right: true }, clientMs: Date.now() };
      assert.equal((await post(host, "/input", input)).body.accepted, true);
      for (const body of [{ ownerToken: "wrong" }, { ownerToken: player.token }, {}]) {
        const rejected = await post(host, "/rematch", body);
        assert.equal(host.sim, sim);
        assert.equal(sim.getFrame(), frame);
        assert.equal(host.session.room.phase, "playing");
        assert.equal(rejected.status, 403);
        assert.equal(rejected.body.reason, "owner_only");
      }
      const publicFrame = host.tick();
      assert.equal((publicFrame.world as { inputs: unknown[] }).inputs.length, 1);
      assert.equal(sim.getFrame(), frame + 1);
    } finally { await host.close(); }
  });

  it("authorized rematch clears old sequences/queued commands, while reconnect retains replay protection", async () => {
    const { host, players, owner } = await readyHost();
    try {
      assert.equal((await post(host, "/start", { ownerToken: owner.token })).body.ok, true);
      const oldSim = host.sim;
      const player = players[0];
      const input = { participantId: player.id, token: player.token, seatIndex: player.seatIndex,
        sequence: 37, tick: 100, semantic: { attack: true }, clientMs: Date.now() };
      assert.equal((await post(host, "/input", input)).body.accepted, true);
      host.session.setResult({ completed: true }); // Declared room-lifecycle fixture, not an earned gameplay result.
      const rematch = await post(host, "/rematch", { ownerToken: owner.token });
      assert.equal(rematch.status, 200);
      assert.equal(rematch.body.ok, true);
      assert.equal(host.sim, null);
      assert.equal(host.session.room.phase, "lobby");
      assert.equal(host.session.publicGameState().result, null);
      for (const participant of players) {
        assert.equal((await post(host, "/ready", {
          participantId: participant.id, token: participant.token, ready: true,
        })).body.ok, true);
      }
      assert.equal(host.startMatch().ok, true); // Trusted local display-host API retains its owner authority.
      assert.notEqual(host.sim, oldSim);
      assert.equal(host.sim!.getFrame(), 0);
      assert.equal((host.tick().world as { inputs: unknown[] }).inputs.length, 0);
      const fresh = await post(host, "/input", { ...input, sequence: 1, tick: 1 });
      assert.equal(fresh.body.accepted, true);
      assert.equal((await post(host, "/input", { ...input, sequence: 1, tick: 1 })).body.reason, "stale_sequence");
      host.session.disconnect(player.id);
      assert.equal((await post(host, "/reconnect", { code: host.session.room.code, token: player.token })).body.ok, true);
      assert.equal((await post(host, "/input", { ...input, sequence: 1, tick: 1 })).body.reason, "stale_sequence");
      assert.equal((await post(host, "/input", { ...input, sequence: 2, tick: 2 })).body.accepted, true);
    } finally { await host.close(); }
  });

  it("a completed round's rate window cannot block the first input of a legitimate rematch", async () => {
    const { host, players, owner } = await readyHost();
    try {
      assert.equal(host.startMatch().ok, true);
      const player = players[0];
      const now = Date.now(); // Fixed clock in the actual session API, not a device performance measurement.
      const input = { participantId: player.id, token: player.token, seatIndex: player.seatIndex,
        sequence: 0, tick: 0, semantic: { shield: true }, clientMs: now };
      for (let sequence = 0; sequence < INPUT_RATE_LIMIT_PER_SEC; sequence++) {
        assert.equal(host.session.submitInput({ ...input, sequence }, now).accepted, true);
      }
      assert.equal(host.session.submitInput({ ...input, sequence: INPUT_RATE_LIMIT_PER_SEC }, now).reason, "input_rate_limited");
      host.session.setResult({ completed: true }); // Explicit session-only lifecycle setup.
      assert.equal((await post(host, "/rematch", { ownerToken: owner.token })).body.ok, true);
      for (const p of players) assert.equal(host.session.setReady(p.id, p.token, true).ok, true);
      assert.equal(host.startMatch().ok, true);
      assert.equal(host.session.submitInput(input, now).accepted, true);
    } finally { await host.close(); }
  });
});
