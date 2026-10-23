import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { describe, it } from "node:test";
import { startLanPartyHost } from "../src/index.js";
import type { PartySimInput } from "../src/hostAuthoritativeParty.js";

type Joined = { id: string; token: string; seatIndex: number };
type WorldPlayer = { seatIndex: number; x: number; y: number; stocks: number };

const CLIENT = `
const [url, rawBody, contentType] = process.argv.slice(1);
const res = await fetch(url, {
  method: "POST",
  headers: { "content-type": contentType },
  body: rawBody,
});
const text = await res.text();
process.stdout.write(JSON.stringify({ status: res.status, text }));
`;

function postFromProcess(
  url: string,
  rawBody: string,
  contentType = "application/json",
): Promise<{ status: number; body: Record<string, unknown> | null; text: string }> {
  return new Promise((resolve, reject) => {
    const child = spawn(
      process.execPath,
      ["--input-type=module", "-e", CLIENT, "--", url, rawBody, contentType],
      { stdio: ["ignore", "pipe", "pipe"] },
    );
    let stdout = "";
    let stderr = "";
    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");
    child.stdout.on("data", (chunk) => {
      stdout += chunk;
    });
    child.stderr.on("data", (chunk) => {
      stderr += chunk;
    });
    child.on("error", reject);
    child.on("close", (code) => {
      if (code !== 0) {
        reject(new Error(`client process ${code}: ${stderr || stdout}`));
        return;
      }
      const parsed = JSON.parse(stdout) as { status: number; text: string };
      let body: Record<string, unknown> | null = null;
      try {
        body = JSON.parse(parsed.text) as Record<string, unknown>;
      } catch {
        body = null;
      }
      resolve({ status: parsed.status, body, text: parsed.text });
    });
  });
}

describe("two client posted frames", () => {
  it("consumes two process posts, rejects malformed input, and moves only from left/right", async () => {
    const host = await startLanPartyHost({
      gameId: "anime-aggressors",
      ownerDisplayName: "Host",
      maxPlayerSeats: 3,
    });
    try {
      const base = host.url;
      const code = host.session.room.code;
      const joined: Joined[] = [];
      for (const displayName of ["RightGrab", "LeftOnly", "Silent"]) {
        const join = await postFromProcess(
          `${base}/join`,
          JSON.stringify({ code, displayName, role: "PLAYER" }),
        );
        assert.equal(join.status, 200, join.text);
        assert.equal(join.body?.ok, true, join.text);
        const participant = join.body?.participant as Joined;
        joined.push(participant);
        const ready = await postFromProcess(
          `${base}/ready`,
          JSON.stringify({
            participantId: participant.id,
            token: participant.token,
            ready: true,
          }),
        );
        assert.equal(ready.body?.ok, true, ready.text);
      }

      const [rightGrab, leftOnly, silent] = joined;
      assert.ok(rightGrab && leftOnly && silent);
      const owner = host.session.room.participants.find((p) => p.id === host.session.room.ownerId);
      assert.ok(owner);
      const start = await postFromProcess(
        `${base}/start`,
        JSON.stringify({ ownerToken: owner.token }),
      );
      assert.equal(start.body?.ok, true, start.text);

      const malformed = await postFromProcess(`${base}/input`, "{not-json", "application/json");
      assert.equal(malformed.status, 500, malformed.text);
      assert.equal(malformed.body?.ok, false, malformed.text);
      assert.notEqual(malformed.body?.accepted, true);

      const [postedRight, postedLeft] = await Promise.all([
        postFromProcess(
          `${base}/input`,
          JSON.stringify({
            participantId: rightGrab.id,
            token: rightGrab.token,
            seatIndex: rightGrab.seatIndex,
            sequence: 1,
            tick: 1,
            semantic: { grab: true, attack: true, right: true },
            clientMs: 1,
          }),
        ),
        postFromProcess(
          `${base}/input`,
          JSON.stringify({
            participantId: leftOnly.id,
            token: leftOnly.token,
            seatIndex: leftOnly.seatIndex,
            sequence: 1,
            tick: 1,
            semantic: { left: true },
            clientMs: 1,
          }),
        ),
      ]);
      assert.equal(postedRight.body?.accepted, true, postedRight.text);
      assert.equal(postedLeft.body?.accepted, true, postedLeft.text);

      const before = new Map(
        host.sim!.getState().players.map((player) => [player.id, { ...player }]),
      );
      const served = host.tick();
      const inputs = (served.world.inputs ?? []) as PartySimInput[];
      const players = (served.world.players ?? []) as WorldPlayer[];
      const rightFrame = inputs.find((input) => input.seatIndex === rightGrab.seatIndex);
      const leftFrame = inputs.find((input) => input.seatIndex === leftOnly.seatIndex);
      assert.ok(rightFrame, JSON.stringify(inputs));
      assert.ok(leftFrame, JSON.stringify(inputs));
      assert.equal(inputs.some((input) => input.seatIndex === silent.seatIndex), false);
      assert.equal(rightFrame.frame.grab, true);
      assert.equal(rightFrame.frame.attack, true);
      assert.equal(rightFrame.frame.right, true);
      assert.equal(leftFrame.frame.left, true);
      assert.equal(leftFrame.frame.grab, false);

      const rightPlayer = players.find((player) => player.seatIndex === rightGrab.seatIndex);
      const leftPlayer = players.find((player) => player.seatIndex === leftOnly.seatIndex);
      const silentPlayer = players.find((player) => player.seatIndex === silent.seatIndex);
      assert.ok(rightPlayer && leftPlayer && silentPlayer);
      const rightBefore = before.get(rightGrab.seatIndex);
      const leftBefore = before.get(leftOnly.seatIndex);
      const silentBefore = before.get(silent.seatIndex);
      assert.ok(rightBefore && leftBefore && silentBefore);
      assert.equal(rightPlayer.x, rightBefore.x + 256);
      assert.equal(leftPlayer.x, leftBefore.x - 256);
      assert.equal(silentPlayer.x, silentBefore.x);
      assert.equal(rightPlayer.y, rightBefore.y);
      assert.equal(leftPlayer.y, leftBefore.y);
      assert.equal(silentPlayer.y, silentBefore.y);
      assert.equal(rightPlayer.stocks, rightBefore.stocks);
      assert.equal(leftPlayer.stocks, leftBefore.stocks);
      assert.equal(silentPlayer.stocks, silentBefore.stocks);

      const after = host.sim!.getState().players;
      for (const player of after) {
        const prior = before.get(player.id);
        assert.ok(prior);
        assert.equal(player.damage, prior.damage);
        assert.equal(player.grabTargetId, prior.grabTargetId);
        assert.equal(player.grabbedByPlayerId, prior.grabbedByPlayerId);
        assert.equal(player.vx, prior.vx);
        assert.equal(player.vy, prior.vy);
      }

      host.session.disconnect(rightGrab.id);
      const recon = await postFromProcess(
        `${base}/reconnect`,
        JSON.stringify({ code, token: rightGrab.token, participantId: rightGrab.id }),
      );
      assert.equal(recon.body?.ok, true, recon.text);
      const resumed = recon.body?.participant as Joined;
      assert.equal(resumed.seatIndex, rightGrab.seatIndex);
      assert.equal(resumed.id, rightGrab.id);

      const repost = await postFromProcess(
        `${base}/input`,
        JSON.stringify({
          participantId: resumed.id,
          token: resumed.token,
          seatIndex: resumed.seatIndex,
          sequence: 2,
          tick: 2,
          semantic: { grab: true, right: true },
          clientMs: 2,
        }),
      );
      assert.equal(repost.body?.accepted, true, repost.text);
      const second = host.tick();
      const secondInputs = (second.world.inputs ?? []) as PartySimInput[];
      const again = secondInputs.find((input) => input.seatIndex === rightGrab.seatIndex);
      assert.ok(again);
      assert.equal(again.frame.grab, true);
      assert.equal(again.frame.right, true);
      assert.equal(secondInputs.some((input) => input.seatIndex === silent.seatIndex), false);
      const moved = ((second.world.players ?? []) as WorldPlayer[]).find(
        (player) => player.seatIndex === rightGrab.seatIndex,
      );
      assert.equal(moved?.x, rightPlayer.x + 256);
    } finally {
      await host.close();
    }
  });
});
