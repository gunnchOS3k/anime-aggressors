import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { renderBrowserControllerHtml, startLanPartyHost } from "../src/index.js";
import type { PartySimInput } from "../src/hostAuthoritativeParty.js";

type Joined = { id: string; token: string; seatIndex: number };

async function post(base: string, path: string, body: unknown): Promise<Record<string, unknown>> {
  const res = await fetch(`${base}${path}`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
  return (await res.json()) as Record<string, unknown>;
}

describe("PartyLink grab", () => {
  it("browser pad offers grab the same way it offers the other carried actions", () => {
    const html = renderBrowserControllerHtml({ gameId: "anime-aggressors" });
    for (const act of ["left", "right", "up", "down", "jump", "attack", "special", "shield", "dodge", "grab"]) {
      assert.match(html, new RegExp(`<button data-act="${act}">`), `missing data-act=${act}`);
    }
    assert.match(html, /<button data-act="grab">Grab<\/button>/);
    const pursuit = renderBrowserControllerHtml({ gameId: "pedestrian-pursuit" });
    assert.equal(pursuit.includes('data-act="grab"'), false);
  });

  it("keeps a second client's intentional grab when the host builds the frame", async () => {
    const host = await startLanPartyHost({
      gameId: "anime-aggressors",
      ownerDisplayName: "Host",
      maxPlayerSeats: 2,
    });
    const seen: PartySimInput[][] = [];
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

      const sim = host.sim;
      const original = sim.advance.bind(sim);
      sim.advance = (inputs, latency) => {
        seen.push(inputs.map((input) => ({ ...input, frame: { ...input.frame } })));
        return original(inputs, latency);
      };

      const [p1, p2] = joined;
      const first = await post(base, "/input", {
        participantId: p1.id,
        token: p1.token,
        seatIndex: p1.seatIndex,
        sequence: 1,
        tick: 1,
        semantic: { shield: true },
        clientMs: Date.now(),
      });
      const second = await post(base, "/input", {
        participantId: p2.id,
        token: p2.token,
        seatIndex: p2.seatIndex,
        sequence: 1,
        tick: 1,
        semantic: { grab: true, attack: true },
        clientMs: Date.now(),
      });
      assert.equal(first.accepted, true, JSON.stringify(first));
      assert.equal(second.accepted, true, JSON.stringify(second));

      host.tick();
      assert.equal(seen.length, 1);
      const frames = seen[0]!;
      const f1 = frames.find((input) => input.seatIndex === p1.seatIndex)?.frame;
      const f2 = frames.find((input) => input.seatIndex === p2.seatIndex)?.frame;
      assert.ok(f1 && f2);
      assert.equal(f1.shield, true);
      assert.equal(f1.grab, false);
      assert.equal(f2.attack, true);
      assert.equal(f2.grab, true, "host dropped semantic.grab while keeping semantic.attack");
    } finally {
      await host.close();
    }
  });
});
