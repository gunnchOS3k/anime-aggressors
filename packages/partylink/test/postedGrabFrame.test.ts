import assert from "node:assert/strict";
import { readPartyLobbySource } from "./partyLobbySource.js";
import { describe, it } from "node:test";
import { renderBrowserControllerHtml, startLanPartyHost } from "../src/index.js";
import type { PartySimInput } from "../src/hostAuthoritativeParty.js";

type Joined = { id: string; token: string; seatIndex: number };

type ServedFrame = PartySimInput;

async function post(base: string, path: string, body: unknown): Promise<Record<string, unknown>> {
  const res = await fetch(`${base}${path}`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
  return (await res.json()) as Record<string, unknown>;
}

describe("posted grab frame", () => {
  it("serves the second client's posted grab, attack, and right, and does not invent a silent seat", async () => {
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

      const [silent, poster] = joined;
      assert.ok(silent && poster);
      const posted = await post(base, "/input", {
        participantId: poster.id,
        token: poster.token,
        seatIndex: poster.seatIndex,
        sequence: 1,
        tick: 1,
        semantic: { grab: true, attack: true, right: true },
        clientMs: Date.now(),
      });
      assert.equal(posted.accepted, true, JSON.stringify(posted));

      const served = host.tick();
      const inputs = (served.world.inputs ?? []) as ServedFrame[];
      const frame = inputs.find((input) => input.seatIndex === poster.seatIndex);
      assert.ok(frame, `session did not serve the posted frame: ${JSON.stringify(served.world)}`);
      assert.equal(frame.sequence, 1, "served frame is not the posted sequence");
      assert.equal(frame.frame.grab, true, "posted grab was forced false on the served frame");
      assert.equal(frame.frame.attack, true, "posted attack was replaced on the served frame");
      assert.equal(frame.frame.right, true, "posted right was replaced on the served frame");
      const silentFrame = inputs.find((input) => input.seatIndex === silent.seatIndex);
      assert.equal(
        silentFrame,
        undefined,
        `silent seat was given an invented frame: ${JSON.stringify(silentFrame)}`,
      );

      const state = (await fetch(`${base}/state`).then((r) => r.json())) as {
        world: { inputs?: ServedFrame[] };
      };
      const echoed = state.world.inputs?.find((input) => input.seatIndex === poster.seatIndex);
      assert.ok(echoed, `GET /state did not serve the posted frame: ${JSON.stringify(state.world)}`);
      assert.equal(echoed.frame.grab, true);
      assert.equal(echoed.frame.attack, true);
      assert.equal(echoed.frame.right, true);
      assert.equal(
        state.world.inputs?.some((input) => input.seatIndex === silent.seatIndex),
        false,
        "GET /state invented a frame for the silent seat",
      );

      const html = renderBrowserControllerHtml({ gameId: "anime-aggressors" });
      assert.match(html, /<button data-act="grab">Grab<\/button>/);
      const pursuit = renderBrowserControllerHtml({ gameId: "pedestrian-pursuit" });
      assert.equal(pursuit.includes('data-act="grab"'), false);

      const lobby = readPartyLobbySource();
      assert.equal(lobby.includes("attack: frames % 23 === s.seatIndex"), false);
      assert.match(lobby, /consumePostedPartyFrames\(runtime\.session, runtime\.sim!\.getFrame\(\)\)/);
    } finally {
      await host.close();
    }
  });
});
