import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  PARTY_TEAM_MODES,
  requiredSeatsForTeamMode,
  runCapacityLadderE2E,
  runMultiClientE2E,
  startLanPartyHost,
  teamForSeat,
} from "../src/index.js";

describe("Party Mode team selectors", () => {
  it("covers FFA and 2v2/3v3/4v4/2v2v2v2 seat maps", () => {
    assert.deepEqual(PARTY_TEAM_MODES, ["FFA", "2v2", "3v3", "4v4", "2v2v2v2"]);
    assert.equal(requiredSeatsForTeamMode("2v2"), 4);
    assert.equal(requiredSeatsForTeamMode("3v3"), 6);
    assert.equal(requiredSeatsForTeamMode("4v4"), 8);
    assert.equal(requiredSeatsForTeamMode("2v2v2v2"), 8);
    assert.equal(teamForSeat("2v2", 0).mode, "2v2");
    assert.equal(teamForSeat("2v2v2v2", 7).mode, "2v2v2v2");
    const t7 = teamForSeat("2v2v2v2", 7);
    assert.ok(t7.mode === "2v2v2v2" && t7.teamId === 3);
  });
});

describe("LAN join route", () => {
  it("serves controller HTML and room code without using code as auth secret", async () => {
    const host = await startLanPartyHost({
      gameId: "anime-aggressors",
      ownerDisplayName: "Host",
      maxPlayerSeats: 4,
    });
    try {
      const health = await fetch(`${host.url}/health`).then((r) => r.json());
      assert.equal(health.ok, true);
      assert.equal(health.publicRelay, false);
      const html = await fetch(host.controllerUrl).then((r) => r.text());
      assert.match(html, /PartyLink Controller/);
      assert.match(html, /PLAYER/);
      assert.match(html, /SPECTATOR/);
      assert.ok(host.qrPayload.includes(host.session.room.code));
      assert.ok(!host.qrPayload.includes(host.session.room.participants[0]!.token));
    } finally {
      await host.close();
    }
  });
});

describe("Browser multi-client E2E ladder", () => {
  it("passes 2-client topology (display + 2 players + spectator)", async () => {
    const r = await runMultiClientE2E({ playerCount: 2 });
    assert.equal(r.pass, true, JSON.stringify(r));
    assert.equal(r.fighterEntityCount, 2);
  });

  it("passes 4-client E2E", async () => {
    const r = await runMultiClientE2E({ playerCount: 4, teamMode: "2v2" });
    assert.equal(r.pass, true, JSON.stringify(r));
    assert.equal(r.fighterEntityCount, 4);
  });

  it("passes 6-client E2E", async () => {
    const r = await runMultiClientE2E({ playerCount: 6, teamMode: "3v3" });
    assert.equal(r.pass, true, JSON.stringify(r));
    assert.equal(r.fighterEntityCount, 6);
  });

  it("passes 8-client E2E with live Arena View state", async () => {
    const r = await runMultiClientE2E({ playerCount: 8, teamMode: "2v2v2v2" });
    assert.equal(r.pass, true, JSON.stringify(r));
    assert.equal(r.fighterEntityCount, 8);
    assert.equal(r.arenaLiveOk, true);
    assert.equal(r.lateSpectatorOk, true);
    assert.equal(r.reconnectOk, true);
    assert.equal(r.rematchOk, true);
  });

  it("capacity ladder 2/4/6/8 all pass", async () => {
    const ladder = await runCapacityLadderE2E([2, 4, 6, 8]);
    assert.equal(ladder.allPass, true, JSON.stringify(ladder.results));
  });
});
