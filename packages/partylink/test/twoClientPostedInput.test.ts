import assert from "node:assert/strict";
import fs from "node:fs";
import { describe, it } from "node:test";
import { consumePostedPartyFrames, startLanPartyHost } from "../src/index.js";

type Joined = { id: string; token: string; seatIndex: number };

async function post(base: string, path: string, body: unknown): Promise<Record<string, unknown>> {
  const res = await fetch(`${base}${path}`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
  return (await res.json()) as Record<string, unknown>;
}

describe("two-client posted input", () => {
  it("serves the second client's posted attack and right instead of a synthesized frame", async () => {
    const host = await startLanPartyHost({
      gameId: "anime-aggressors",
      ownerDisplayName: "Host",
      maxPlayerSeats: 2,
    });
    try {
      const base = host.url;
      const code = host.session.room.code;
      const joined: Joined[] = [];
      for (const displayName of ["P1", "P2"]) {
        const join = await post(base, "/join", { code, displayName, role: "PLAYER" });
        assert.equal(join.ok, true, JSON.stringify(join));
        const participant = join.participant as Joined;
        joined.push(participant);
        const ready = await post(base, "/ready", {
          participantId: participant.id,
          token: participant.token,
          ready: true,
        });
        assert.equal(ready.ok, true, JSON.stringify(ready));
      }
      const owner = host.session.room.participants.find((p) => p.id === host.session.room.ownerId);
      assert.ok(owner);
      const start = await post(base, "/start", { ownerToken: owner.token });
      assert.equal(start.ok, true, JSON.stringify(start));
      assert.ok(host.sim);

      const p2 = joined[1]!;
      const posted = await post(base, "/input", {
        participantId: p2.id,
        token: p2.token,
        seatIndex: p2.seatIndex,
        sequence: 1,
        tick: 1,
        semantic: { right: true, attack: true, grab: true },
        clientMs: Date.now(),
      });
      assert.equal(posted.accepted, true, JSON.stringify(posted));

      const frames = consumePostedPartyFrames(host.session, 2);
      const served = frames.find((input) => input.seatIndex === p2.seatIndex);
      assert.ok(served, "host served no frame for the second client");
      assert.equal(served.frame.attack, true, "lobby replaced the second client's posted attack");
      assert.equal(served.frame.right, true, "lobby replaced the second client's posted right");
      assert.equal(frames.length, 1, "host invented frames for seats that did not post");
      assert.equal(served.sequence, 1, "host replaced the posted sequence");
      assert.equal(
        served.frame.grab,
        false,
        "grab stays forced false until unmerged #127; this branch does not map semantic.grab",
      );

      const state = (await fetch(`${base}/state`).then((r) => r.json())) as {
        world: { inputs?: typeof frames };
      };
      const echoed = state.world.inputs?.find((input) => input.seatIndex === p2.seatIndex);
      assert.ok(echoed, `GET /state did not serve the posted frame: ${JSON.stringify(state.world)}`);
      assert.equal(echoed.frame.attack, true);
      assert.equal(echoed.frame.right, true);
      assert.equal(echoed.frame.grab, false);

      const before = host.sim.getState().players.find((p) => p.id === p2.seatIndex);
      assert.ok(before);
      host.sim.advance(frames, []);
      const after = host.sim.getState().players.find((p) => p.id === p2.seatIndex);
      assert.ok(after);
      assert.equal(after.stocks, before.stocks);
      assert.equal(after.damage, before.damage);
      assert.equal(after.x, before.x + 256);

      const lobby = fs.readFileSync(
        new URL("../../../apps/web/src/screens/PartyLobbyScreen.ts", import.meta.url),
        "utf8",
      );
      assert.match(lobby, /consumePostedPartyFrames\(runtime\.session, runtime\.sim!\.getFrame\(\)\)/);
      assert.equal(lobby.includes("attack: frames % 23 === s.seatIndex"), false);
      assert.equal(lobby.includes("grab: false"), false);
    } finally {
      await host.close();
    }
  });
});
