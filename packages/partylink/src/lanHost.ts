/**
 * Same-room / LAN PartyLink join host (V1).
 * Room code is public; auth is opaque participant token.
 * Does NOT claim public Internet relay.
 */

import http from "node:http";
import type { AddressInfo } from "node:net";
import { renderBrowserControllerHtml } from "./browserController.js";
import { PartyRoomSession, type CreateRoomOptions } from "./partyRoom.js";
import { HostAuthoritativePartySim, partyGameConfig } from "./hostAuthoritativeParty.js";
import { teamForSeat, type PartyTeamMode } from "./teamAssign.js";
import { buildJoinQrPayload } from "./identity.js";
import type { ControllerInput, PublicGameState } from "./types.js";

export type LanHostOptions = CreateRoomOptions & {
  host?: string;
  port?: number;
  teamMode?: PartyTeamMode;
};

export type LanHostHandle = {
  session: PartyRoomSession;
  sim: HostAuthoritativePartySim | null;
  url: string;
  joinUrl: string;
  controllerUrl: string;
  qrPayload: string;
  port: number;
  teamMode: PartyTeamMode;
  close: () => Promise<void>;
  startMatch: () => { ok: boolean; reason?: string; fighterCount?: number };
  tick: (inputs?: ControllerInput[]) => PublicGameState;
  getPublicState: () => PublicGameState;
};

function readJson(req: http.IncomingMessage): Promise<unknown> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    req.on("data", (c) => chunks.push(Buffer.from(c)));
    req.on("end", () => {
      try {
        const raw = Buffer.concat(chunks).toString("utf8") || "{}";
        resolve(JSON.parse(raw));
      } catch (e) {
        reject(e);
      }
    });
    req.on("error", reject);
  });
}

function sendJson(res: http.ServerResponse, status: number, body: unknown): void {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "access-control-allow-origin": "*",
    "access-control-allow-methods": "GET,POST,OPTIONS",
    "access-control-allow-headers": "content-type",
  });
  res.end(payload);
}

function sendHtml(res: http.ServerResponse, html: string): void {
  res.writeHead(200, {
    "content-type": "text/html; charset=utf-8",
    "access-control-allow-origin": "*",
  });
  res.end(html);
}

function ensureSeatDefaults(session: PartyRoomSession, teamMode: PartyTeamMode): void {
  for (const seat of session.room.seats) {
    if (!seat.participantId) continue;
    const p = session.room.participants.find((x) => x.id === seat.participantId);
    if (!p) continue;
    if (!seat.fighterId) {
      session.setFighter(
        p.id,
        p.token,
        ["ember", "tide", "volt", "shade"][seat.seatIndex % 4]!,
      );
    }
    if (!seat.team) {
      seat.team = teamForSeat(teamMode, seat.seatIndex);
    }
  }
}

export async function startLanPartyHost(opts: LanHostOptions): Promise<LanHostHandle> {
  const session = new PartyRoomSession(opts);
  let sim: HostAuthoritativePartySim | null = null;
  let teamMode: PartyTeamMode = opts.teamMode ?? "FFA";
  const pendingInputs: ControllerInput[] = [];

  const beginMatch = (ownerToken: string) => {
    ensureSeatDefaults(session, teamMode);
    const start = session.startMatch(ownerToken);
    if (!start.ok) return start;
    const n = session.room.seats.filter((s) => s.participantId).length;
    sim = new HostAuthoritativePartySim(partyGameConfig(n));
    return { ok: true as const, fighterCount: n };
  };

  const server = http.createServer(async (req, res) => {
    const url = new URL(req.url ?? "/", `http://${req.headers.host ?? "127.0.0.1"}`);
    if (req.method === "OPTIONS") {
      res.writeHead(204, {
        "access-control-allow-origin": "*",
        "access-control-allow-methods": "GET,POST,OPTIONS",
        "access-control-allow-headers": "content-type",
      });
      res.end();
      return;
    }

    try {
      if (req.method === "GET" && (url.pathname === "/" || url.pathname === "/controller")) {
        sendHtml(
          res,
          renderBrowserControllerHtml({
            gameId: opts.gameId,
            code: session.room.code,
            joinBasePath: "",
          }),
        );
        return;
      }
      if (req.method === "GET" && url.pathname === "/room") {
        sendJson(res, 200, session.getPublicRoom());
        return;
      }
      if (req.method === "GET" && url.pathname === "/state") {
        sendJson(res, 200, session.publicGameState());
        return;
      }
      if (req.method === "GET" && url.pathname === "/health") {
        sendJson(res, 200, {
          ok: true,
          transport: "LAN_WEBSOCKET",
          publicRelay: false,
          code: session.room.code,
        });
        return;
      }

      if (req.method !== "POST") {
        sendJson(res, 404, { ok: false, reason: "not_found" });
        return;
      }

      const body = (await readJson(req)) as Record<string, unknown>;

      if (url.pathname === "/join") {
        const out = session.join({
          code: String(body.code ?? ""),
          displayName: String(body.displayName ?? "Player"),
          role: body.role === "SPECTATOR" ? "SPECTATOR" : "PLAYER",
          resumeToken: typeof body.resumeToken === "string" ? body.resumeToken : undefined,
        });
        sendJson(res, out.ok ? 200 : 400, out);
        return;
      }
      if (url.pathname === "/reconnect") {
        const token = String(body.token ?? "");
        const existing =
          session.room.participants.find((p) => p.token === token) ??
          session.room.spectators.find((p) => p.token === token);
        const out = session.reconnect({
          code: String(body.code ?? session.room.code),
          participantId: existing?.id ?? String(body.participantId ?? ""),
          token,
        });
        sendJson(res, out.ok ? 200 : 400, out);
        return;
      }
      if (url.pathname === "/fighter") {
        sendJson(
          res,
          200,
          session.setFighter(String(body.participantId), String(body.token), String(body.fighterId ?? "ember"), body.bodyVariant === "female" || body.bodyVariant === "male" ? body.bodyVariant : null),
        );
        return;
      }
      if (url.pathname === "/team") {
        const p = session.room.participants.find(
          (x) => x.id === body.participantId && x.token === body.token,
        );
        if (!p || p.seatIndex == null) {
          sendJson(res, 400, { ok: false, reason: "not_seated_player" });
          return;
        }
        const raw = String(body.team ?? "FFA");
        if (raw === "FFA") {
          sendJson(res, 200, session.setTeam(p.id, p.token, { mode: "FFA" }));
        } else {
          const assignment = teamForSeat(teamMode === "FFA" ? "2v2v2v2" : teamMode, p.seatIndex);
          if (assignment.mode !== "FFA") {
            (assignment as { teamId: number }).teamId = Number(raw);
          }
          sendJson(res, 200, session.setTeam(p.id, p.token, assignment));
        }
        return;
      }
      if (url.pathname === "/ready") {
        sendJson(
          res,
          200,
          session.setReady(String(body.participantId), String(body.token), Boolean(body.ready ?? true)),
        );
        return;
      }
      if (url.pathname === "/start") {
        const owner = session.room.participants.find((p) => p.id === session.room.ownerId)!;
        const token = String(body.ownerToken ?? owner.token);
        if (typeof body.teamMode === "string") teamMode = body.teamMode as PartyTeamMode;
        const start = beginMatch(token);
        sendJson(res, start.ok ? 200 : 400, start);
        return;
      }
      if (url.pathname === "/input") {
        const input = body as unknown as ControllerInput;
        const ack = session.submitInput(input);
        if (ack.accepted) pendingInputs.push(input);
        sendJson(res, 200, ack);
        return;
      }
      if (url.pathname === "/rematch") {
        const owner = session.room.participants.find((p) => p.id === session.room.ownerId)!;
        sim = null;
        sendJson(res, 200, session.rematch(String(body.ownerToken ?? owner.token)));
        return;
      }

      sendJson(res, 404, { ok: false, reason: "not_found" });
    } catch (e) {
      sendJson(res, 500, { ok: false, reason: e instanceof Error ? e.message : "error" });
    }
  });

  const listenHost = opts.host ?? "0.0.0.0";
  const listenPort = opts.port ?? 0;

  await new Promise<void>((resolve, reject) => {
    server.once("error", reject);
    server.listen(listenPort, listenHost, () => resolve());
  });

  const addr = server.address() as AddressInfo;
  const reachHost = listenHost === "0.0.0.0" ? "127.0.0.1" : listenHost;
  const base = `http://${reachHost}:${addr.port}`;
  const joinUrl = `${base}/controller?code=${session.room.code}`;
  const qrPayload = buildJoinQrPayload({
    code: session.room.code,
    gameId: opts.gameId,
    role: "PLAYER",
    baseUrl: `${base}/controller`,
  });

  const handle: LanHostHandle = {
    session,
    get sim() {
      return sim;
    },
    url: base,
    joinUrl,
    controllerUrl: `${base}/controller`,
    qrPayload,
    port: addr.port,
    get teamMode() {
      return teamMode;
    },
    close: () =>
      new Promise((resolve, reject) => {
        server.close((err) => (err ? reject(err) : resolve()));
      }),
    startMatch: () => {
      const owner = session.room.participants.find((p) => p.id === session.room.ownerId)!;
      return beginMatch(owner.token);
    },
    tick: (inputs = []) => {
      const batch = [...pendingInputs, ...inputs];
      pendingInputs.length = 0;
      if (sim) {
        sim.advance(
          batch.map((i) => ({
            seatIndex: i.seatIndex,
            sequence: i.sequence,
            frame: {
              frame: 0,
              playerId: i.seatIndex,
              left: Boolean(i.semantic.left ?? i.semantic.steerLeft),
              right: Boolean(i.semantic.right ?? i.semantic.steerRight),
              up: Boolean(i.semantic.up),
              down: Boolean(i.semantic.down),
              jump: Boolean(i.semantic.jump),
              attack: Boolean(i.semantic.attack),
              special: Boolean(i.semantic.special),
              shield: Boolean(i.semantic.shield),
              dodge: Boolean(i.semantic.dodge),
              grab: false,
            },
          })),
          batch.map(() => 5),
        );
        session.advanceHostTick();
        const state = sim.getState();
        const pub = session.publicGameState();
        pub.world = {
          players: state.players.map((p) => ({
            seatIndex: p.id,
            x: p.x,
            y: p.y,
            stocks: p.stocks,
          })),
          arena: sim.arenaCamera(),
          hudSlots: sim.hudSlots(),
        };
        return pub;
      }
      return session.publicGameState();
    },
    getPublicState: () => session.publicGameState(),
  };

  return handle;
}
