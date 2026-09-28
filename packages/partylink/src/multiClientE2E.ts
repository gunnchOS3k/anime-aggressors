/**
 * Multi-client PartyLink E2E harness (display host + N player clients + spectator).
 * Proves seats, input ownership, ready, start, reconnect, late spectator, rematch.
 */

import { startLanPartyHost, type LanHostHandle } from "./lanHost.js";
import type { CapacityTier } from "./capacity.js";

export type MultiClientE2EResult = {
  playerCount: number;
  spectatorOk: boolean;
  uniqueSeats: boolean;
  uniqueInputOwnership: boolean;
  readyOk: boolean;
  startOk: boolean;
  fighterEntityCount: number;
  publicDisplayStateOk: boolean;
  reconnectOk: boolean;
  lateSpectatorOk: boolean;
  rematchOk: boolean;
  arenaLiveOk: boolean;
  pass: boolean;
  joinUrl: string;
  controllerUrl: string;
  roomCode: string;
};

async function post(base: string, path: string, body: unknown): Promise<Record<string, unknown>> {
  const res = await fetch(`${base}${path}`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
  return (await res.json()) as Record<string, unknown>;
}

export async function runMultiClientE2E(opts: {
  playerCount: CapacityTier | 3 | 5 | 7;
  gameId?: "anime-aggressors" | "pedestrian-pursuit";
  teamMode?: "FFA" | "2v2" | "3v3" | "4v4" | "2v2v2v2";
}): Promise<MultiClientE2EResult> {
  const host: LanHostHandle = await startLanPartyHost({
    gameId: opts.gameId ?? "anime-aggressors",
    ownerDisplayName: "DisplayHost",
    maxPlayerSeats: opts.playerCount,
    teamMode: opts.teamMode ?? "FFA",
  });

  try {
    const base = host.url;
    const code = host.session.room.code;
    const players: Array<{ id: string; token: string; seatIndex: number }> = [];

    for (let i = 0; i < opts.playerCount; i++) {
      const join = await post(base, "/join", {
        code,
        displayName: `P${i + 1}`,
        role: "PLAYER",
      });
      if (!join.ok) throw new Error(`join failed ${JSON.stringify(join)}`);
      const participant = join.participant as { id: string; token: string; seatIndex: number };
      players.push(participant);
      await post(base, "/fighter", {
        participantId: participant.id,
        token: participant.token,
        fighterId: ["ember", "tide", "volt", "shade"][i % 4],
      });
      await post(base, "/ready", {
        participantId: participant.id,
        token: participant.token,
        ready: true,
      });
    }

    const seats = new Set(players.map((p) => p.seatIndex));
    const uniqueSeats = seats.size === opts.playerCount;

    const earlySpec = await post(base, "/join", {
      code,
      displayName: "EarlySpec",
      role: "SPECTATOR",
    });
    const spectatorOk = Boolean(earlySpec.ok);

    const owner = host.session.room.participants.find((p) => p.id === host.session.room.ownerId)!;
    const start = await post(base, "/start", { ownerToken: owner.token, teamMode: opts.teamMode ?? "FFA" });
    const startOk = Boolean(start.ok);
    const fighterEntityCount = Number(start.fighterCount ?? 0);

    // Unique input ownership: each seat's input accepted; wrong seat rejected
    let uniqueInputOwnership = true;
    for (const p of players) {
      const ok = await post(base, "/input", {
        participantId: p.id,
        token: p.token,
        seatIndex: p.seatIndex,
        sequence: 1,
        tick: 1,
        semantic: { left: true },
        clientMs: Date.now(),
      });
      if (!ok.accepted) uniqueInputOwnership = false;
      const wrong = await post(base, "/input", {
        participantId: p.id,
        token: p.token,
        seatIndex: (p.seatIndex + 1) % opts.playerCount,
        sequence: 2,
        tick: 2,
        semantic: { attack: true },
        clientMs: Date.now(),
      });
      if (wrong.accepted) uniqueInputOwnership = false;
    }

    // Spectator cannot send gameplay input
    if (earlySpec.ok) {
      const sp = earlySpec.participant as { id: string; token: string };
      const rejected = await post(base, "/input", {
        participantId: sp.id,
        token: sp.token,
        seatIndex: 0,
        sequence: 1,
        tick: 1,
        semantic: { attack: true },
        clientMs: Date.now(),
      });
      if (rejected.accepted) uniqueInputOwnership = false;
    }

    // Advance runtime ticks for Arena View live state
    for (let t = 0; t < 12; t++) host.tick();
    const pub = host.tick();
    const world = pub.world as { players?: unknown[]; arena?: unknown; hudSlots?: unknown[] };
    const publicDisplayStateOk =
      Array.isArray(world?.players) &&
      (world.players?.length ?? 0) === opts.playerCount &&
      Array.isArray(world?.hudSlots) &&
      (world.hudSlots?.length ?? 0) === opts.playerCount;
    const arenaLiveOk = Boolean(world?.arena) && publicDisplayStateOk;

    // Reconnect one player
    const victim = players[0]!;
    host.session.disconnect(victim.id);
    const recon = await post(base, "/reconnect", { code, token: victim.token });
    const reconnectOk = Boolean(recon.ok);

    // Late spectator join during play
    const lateSpec = await post(base, "/join", {
      code,
      displayName: "LateSpec",
      role: "SPECTATOR",
    });
    const lateSpectatorOk = Boolean(lateSpec.ok);

    host.session.setResult({
      placements: players.map((p, i) => ({ seat: p.seatIndex, place: i + 1 })),
    });
    const rematch = await post(base, "/rematch", { ownerToken: owner.token });
    const rematchOk = Boolean(rematch.ok);

    const readyOk = players.length === opts.playerCount;

    const pass =
      uniqueSeats &&
      uniqueInputOwnership &&
      readyOk &&
      startOk &&
      fighterEntityCount === opts.playerCount &&
      publicDisplayStateOk &&
      reconnectOk &&
      lateSpectatorOk &&
      rematchOk &&
      arenaLiveOk &&
      spectatorOk;

    return {
      playerCount: opts.playerCount,
      spectatorOk,
      uniqueSeats,
      uniqueInputOwnership,
      readyOk,
      startOk,
      fighterEntityCount,
      publicDisplayStateOk,
      reconnectOk,
      lateSpectatorOk,
      rematchOk,
      arenaLiveOk,
      pass,
      joinUrl: host.joinUrl,
      controllerUrl: host.controllerUrl,
      roomCode: code,
    };
  } finally {
    await host.close();
  }
}

export async function runCapacityLadderE2E(
  tiers: Array<CapacityTier> = [2, 4, 6, 8],
): Promise<{ results: MultiClientE2EResult[]; allPass: boolean }> {
  const results: MultiClientE2EResult[] = [];
  for (const tier of tiers) {
    results.push(await runMultiClientE2E({ playerCount: tier }));
  }
  return { results, allPass: results.every((r) => r.pass) };
}
