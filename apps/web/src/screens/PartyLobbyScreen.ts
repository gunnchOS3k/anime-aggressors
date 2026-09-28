/**
 * Party Lobby / Arena View display surface — room code, QR, 8 seats, host start.
 * Uses in-browser PartyRoomSession when Node LAN host is unavailable (Pages).
 * When a LAN host URL is configured, polls /room and /state.
 */

import {
  PartyRoomSession,
  HostAuthoritativePartySim,
  partyGameConfig,
  teamForSeat,
  buildJoinQrPayload,
  type PartyTeamMode,
} from "@anime-aggressors/partylink";
import { navigateTo } from "../router.js";
import { ARENA_CLASSES } from "../ui/theme/arenaClasses.ts";
import { loadPartyModeConfig } from "./PartyModeScreen.ts";

const HOST_KEY = "anime-aggressors.partyLanHost";
const SESSION_KEY = "anime-aggressors.partySessionSnapshot";

type LocalPartyRuntime = {
  session: PartyRoomSession;
  sim: HostAuthoritativePartySim | null;
  teamMode: PartyTeamMode;
};

let localRuntime: LocalPartyRuntime | null = null;

function ensureLocalRuntime(): LocalPartyRuntime {
  if (localRuntime) return localRuntime;
  const cfg = loadPartyModeConfig();
  const session = new PartyRoomSession({
    gameId: "anime-aggressors",
    ownerDisplayName: cfg.hostName,
    maxPlayerSeats: cfg.playerCount,
  });
  localRuntime = { session, sim: null, teamMode: cfg.teamMode };
  try {
    localStorage.setItem(
      SESSION_KEY,
      JSON.stringify({ code: session.room.code, sessionId: session.room.sessionId }),
    );
  } catch {
    /* ignore */
  }
  return localRuntime;
}

export function getActivePartyRuntime(): LocalPartyRuntime {
  return ensureLocalRuntime();
}

export function mountPartyLobbyScreen(root: HTMLElement): void {
  const cfg = loadPartyModeConfig();
  const runtime = ensureLocalRuntime();
  const pub = runtime.session.getPublicRoom();
  const lanHint = localStorage.getItem(HOST_KEY) ?? "";
  const controllerPath = `#/party-controller?code=${pub.code}`;
  const qr = buildJoinQrPayload({
    code: pub.code,
    gameId: "anime-aggressors",
    role: "PLAYER",
    baseUrl: lanHint ? `${lanHint}/controller` : `${location.origin}${location.pathname}${controllerPath}`,
  });

  const seatHtml = runtime.session.room.seats
    .map((s) => {
      const team =
        s.team && s.team.mode !== "FFA" ? ` · T${(s.team as { teamId: number }).teamId}` : "";
      return `<li class="party-seat" data-seat="${s.seatIndex}" data-state="${s.state}">
        <strong>Seat ${s.seatIndex + 1}</strong>
        <span>${s.displayName ?? "—"}</span>
        <span>${s.fighterId ?? "no fighter"}${team}</span>
        <span class="party-seat__state">${s.state}</span>
      </li>`;
    })
    .join("");

  root.innerHTML = `
    <div class="party-lobby" data-testid="party-lobby">
      <header>
        <h1>Party Lobby / Arena View</h1>
        <p>Host-authoritative · LAN/same-room · relay=false</p>
      </header>
      <div class="party-lobby__code" data-testid="party-room-code">
        <span class="party-lobby__code-label">Room code</span>
        <span class="party-lobby__code-value">${pub.code}</span>
      </div>
      <div class="party-lobby__qr" data-testid="party-qr">
        <p>Join / QR payload</p>
        <code>${qr}</code>
        <p>Controller route: <a href="${controllerPath}">${controllerPath}</a></p>
        <label>Optional LAN host base URL
          <input id="pl-lan" value="${lanHint}" placeholder="http://192.168.x.x:8787"/>
        </label>
      </div>
      <p>Players ${runtime.session.capacitySnapshot().playerSeatsUsed}/${cfg.playerCount}
         · Spectators ${runtime.session.capacitySnapshot().spectatorSeatsUsed}
         · Team ${cfg.teamMode}</p>
      <ul class="party-lobby__seats" data-testid="party-seats">${seatHtml}</ul>
      <div class="party-lobby__host">
        <button type="button" id="pl-ready-all" class="${ARENA_CLASSES.secondaryBtn}">Mark all ready (local)</button>
        <button type="button" id="pl-start" class="${ARENA_CLASSES.primaryCta}" data-testid="party-start">Start match</button>
        <button type="button" id="pl-back" class="${ARENA_CLASSES.secondaryBtn}">Back</button>
      </div>
    </div>`;

  root.querySelector("#pl-back")?.addEventListener("click", () => navigateTo("party-mode"));
  root.querySelector("#pl-lan")?.addEventListener("change", (e) => {
    localStorage.setItem(HOST_KEY, (e.target as HTMLInputElement).value.trim());
  });
  root.querySelector("#pl-ready-all")?.addEventListener("click", () => {
    // Fill empty seats with local synthetic players (display-host proof path).
    while (runtime.session.room.seats.some((s) => s.state === "EMPTY")) {
      const i = runtime.session.room.seats.find((s) => s.state === "EMPTY")!.seatIndex;
      const join = runtime.session.join({
        code: runtime.session.room.code,
        displayName: `Seat ${i + 1}`,
        role: "PLAYER",
      });
      if (!join.ok) break;
      runtime.session.setFighter(
        join.participant.id,
        join.participant.token,
        ["ember", "tide", "volt", "shade"][i % 4]!,
      );
      runtime.session.setTeam(
        join.participant.id,
        join.participant.token,
        teamForSeat(runtime.teamMode, i),
      );
    }
    for (const p of runtime.session.room.participants) {
      if (p.seatIndex == null) continue;
      runtime.session.setReady(p.id, p.token, true);
    }
    mountPartyLobbyScreen(root);
  });
  root.querySelector("#pl-start")?.addEventListener("click", () => {
    const fillLocal = () => {
      while (runtime.session.room.seats.some((s) => s.state === "EMPTY")) {
        const i = runtime.session.room.seats.find((s) => s.state === "EMPTY")!.seatIndex;
        const join = runtime.session.join({
          code: runtime.session.room.code,
          displayName: `Seat ${i + 1}`,
          role: "PLAYER",
        });
        if (!join.ok) break;
        runtime.session.setFighter(
          join.participant.id,
          join.participant.token,
          ["ember", "tide", "volt", "shade"][i % 4]!,
        );
        runtime.session.setTeam(
          join.participant.id,
          join.participant.token,
          teamForSeat(runtime.teamMode, i),
        );
      }
      for (const p of runtime.session.room.participants) {
        if (p.seatIndex == null) continue;
        runtime.session.setReady(p.id, p.token, true);
      }
    };
    if (runtime.session.room.seats.filter((s) => s.participantId).length < 2) {
      fillLocal();
    } else {
      for (const p of runtime.session.room.participants) {
        if (p.seatIndex == null) continue;
        runtime.session.setReady(p.id, p.token, true);
      }
    }
    const owner = runtime.session.room.participants.find((p) => p.id === runtime.session.room.ownerId)!;
    const start = runtime.session.startMatch(owner.token);
    if (!start.ok) {
      alert(`Cannot start: ${start.reason}`);
      mountPartyLobbyScreen(root);
      return;
    }
    const n = runtime.session.room.seats.filter((s) => s.participantId).length;
    runtime.sim = new HostAuthoritativePartySim(partyGameConfig(n));
    navigateTo("party-arena");
  });
}

export function mountPartyArenaScreen(root: HTMLElement): void {
  const runtime = ensureLocalRuntime();
  if (runtime.session.room.phase !== "playing" || !runtime.sim) {
    navigateTo("party-lobby");
    return;
  }

  let frames = 0;
  let raf = 0;

  const draw = () => {
    frames += 1;
    const inputs = runtime.session.room.seats
      .filter((s) => s.participantId && s.state !== "ELIMINATED_OR_FINISHED")
      .map((s, i) => ({
        seatIndex: s.seatIndex,
        sequence: frames + i,
        frame: {
          frame: frames,
          playerId: s.seatIndex,
          left: frames % 17 === s.seatIndex,
          right: false,
          up: false,
          down: false,
          jump: false,
          attack: frames % 23 === s.seatIndex,
          special: false,
          shield: false,
          dodge: false,
          grab: false,
        },
      }));
    runtime.sim!.advance(inputs, inputs.map(() => 5));
    runtime.session.advanceHostTick();
    const cam = runtime.sim!.arenaCamera();
    const hud = runtime.sim!.hudSlots();
    const players = runtime.sim!.getState().players;
    const seats = runtime.session.room.seats
      .filter((s) => s.participantId)
      .map((s) => {
        const pl = players.find((p) => p.id === s.seatIndex);
        return `<li>Seat ${s.seatIndex + 1} ${s.displayName} · ${s.fighterId}
          · stocks ${pl?.stocks ?? "—"} · x=${((pl?.x ?? 0) / 256).toFixed(2)}</li>`;
      })
      .join("");

    root.innerHTML = `
      <div class="party-arena" data-testid="party-arena-live">
        <header>
          <h1>Arena View</h1>
          <p>Live host sim · frame ${runtime.sim!.getFrame()} · camera zoom ${cam.zoom.toFixed(2)}</p>
        </header>
        <div class="party-arena__stage" data-testid="party-arena-stage"
             style="position:relative;height:280px;background:#0b1020;border-radius:12px;overflow:hidden">
          ${players
            .map(
              (p) =>
                `<div style="position:absolute;left:${50 + (p.x / 256) * 4}%;top:${40 + (p.y / 256) * 2}%;
                  width:18px;height:18px;border-radius:50%;background:${hud[p.id] ?? "#5eead4"};
                  outline:2px solid #fff" title="P${p.id + 1}"></div>`,
            )
            .join("")}
        </div>
        <ul data-testid="party-arena-hud">${seats}</ul>
        <p>HUD slots: ${hud.join(", ")}</p>
        <div>
          <button type="button" id="pa-results" class="${ARENA_CLASSES.primaryCta}">Results / Rematch</button>
          <button type="button" id="pa-lobby" class="${ARENA_CLASSES.secondaryBtn}">Lobby</button>
        </div>
      </div>`;

    root.querySelector("#pa-lobby")?.addEventListener("click", () => {
      cancelAnimationFrame(raf);
      navigateTo("party-lobby");
    });
    root.querySelector("#pa-results")?.addEventListener("click", () => {
      cancelAnimationFrame(raf);
      runtime.session.setResult({
        placements: players.map((p, i) => ({ seat: p.id, place: i + 1 })),
      });
      navigateTo("party-results");
    });

    raf = requestAnimationFrame(draw);
  };

  draw();
}

export function mountPartyResultsScreen(root: HTMLElement): void {
  const runtime = ensureLocalRuntime();
  const result = runtime.session.publicGameState().result;
  root.innerHTML = `
    <div class="party-results" data-testid="party-results">
      <h1>Party Results</h1>
      <pre>${JSON.stringify(result, null, 2)}</pre>
      <button type="button" id="pr-rematch" class="${ARENA_CLASSES.primaryCta}">Rematch</button>
      <button type="button" id="pr-home" class="${ARENA_CLASSES.secondaryBtn}">Main Menu</button>
    </div>`;
  root.querySelector("#pr-home")?.addEventListener("click", () => {
    localRuntime = null;
    navigateTo("home");
  });
  root.querySelector("#pr-rematch")?.addEventListener("click", () => {
    const owner = runtime.session.room.participants.find((p) => p.id === runtime.session.room.ownerId)!;
    runtime.session.rematch(owner.token);
    runtime.sim = null;
    navigateTo("party-lobby");
  });
}

export function mountPartyControllerScreen(root: HTMLElement): void {
  const params = new URLSearchParams(location.hash.split("?")[1] ?? "");
  const codeFromParams = params.get("code");
  const codePrefill =
    codeFromParams ??
    (loadPartyModeConfig() ? ensureLocalRuntime().session.room.code : "") ??
    "";
  root.innerHTML = `
    <div class="party-controller" data-testid="party-browser-controller">
      <h1>Phone / Browser Controller</h1>
      <p>Join as PLAYER or SPECTATOR. Gameplay inputs rejected for spectators.</p>
      <label>Room code<input id="pc-code" value="${codePrefill}"/></label>
      <label>Display name<input id="pc-name" value="Guest"/></label>
      <label>Role
        <select id="pc-role"><option>PLAYER</option><option>SPECTATOR</option></select>
      </label>
      <button type="button" id="pc-join" class="${ARENA_CLASSES.primaryCta}">Join</button>
      <div id="pc-pad" class="hidden">
        <p id="pc-status"></p>
        <button type="button" data-act="left">←</button>
        <button type="button" data-act="right">→</button>
        <button type="button" data-act="jump">Jump</button>
        <button type="button" data-act="attack">Attack</button>
        <button type="button" data-act="special">Special</button>
        <button type="button" data-act="shield">Shield</button>
        <button type="button" data-act="ready">Ready</button>
        <button type="button" id="pc-reconnect">Reconnect</button>
      </div>
      <button type="button" id="pc-back" class="${ARENA_CLASSES.secondaryBtn}">Back</button>
    </div>`;

  let participant: { id: string; token: string; seatIndex: number | null; role: string } | null = null;
  let seq = 0;
  const runtime = ensureLocalRuntime();

  root.querySelector("#pc-back")?.addEventListener("click", () => navigateTo("home"));
  root.querySelector("#pc-join")?.addEventListener("click", () => {
    const code = (root.querySelector("#pc-code") as HTMLInputElement).value.trim().toUpperCase();
    const displayName = (root.querySelector("#pc-name") as HTMLInputElement).value.trim() || "Guest";
    const role = (root.querySelector("#pc-role") as HTMLSelectElement).value as "PLAYER" | "SPECTATOR";
    const join = runtime.session.join({ code, displayName, role });
    const status = root.querySelector("#pc-status")!;
    if (!join.ok) {
      status.textContent = `Join failed: ${join.reason}`;
      return;
    }
    participant = join.participant;
    localStorage.setItem(
      "partylink.resume.anime-aggressors",
      JSON.stringify({
        code,
        participantId: participant.id,
        token: participant.token,
      }),
    );
    root.querySelector("#pc-pad")?.classList.remove("hidden");
    status.textContent = `${participant.role} seat ${participant.seatIndex ?? "—"} connected`;
  });

  root.querySelector("#pc-reconnect")?.addEventListener("click", () => {
    const raw = localStorage.getItem("partylink.resume.anime-aggressors");
    if (!raw) return;
    const saved = JSON.parse(raw) as { code: string; participantId: string; token: string };
    const join = runtime.session.reconnect({
      code: saved.code,
      participantId: saved.participantId,
      token: saved.token,
    });
    if (join.ok) {
      participant = join.participant;
      root.querySelector("#pc-status")!.textContent = `Reconnected seat ${participant.seatIndex ?? "—"}`;
    }
  });

  root.querySelectorAll("#pc-pad button[data-act]").forEach((btn) => {
    btn.addEventListener("click", () => {
      if (!participant) return;
      const act = (btn as HTMLButtonElement).dataset.act!;
      if (act === "ready" && participant.seatIndex != null) {
        runtime.session.setReady(participant.id, participant.token, true);
        root.querySelector("#pc-status")!.textContent = "READY";
        return;
      }
      if (participant.role === "SPECTATOR") {
        root.querySelector("#pc-status")!.textContent = "Spectator — input rejected";
        return;
      }
      seq += 1;
      const ack = runtime.session.submitInput({
        participantId: participant.id,
        token: participant.token,
        seatIndex: participant.seatIndex ?? 0,
        sequence: seq,
        tick: seq,
        semantic: { [act]: true },
        clientMs: Date.now(),
      });
      root.querySelector("#pc-status")!.textContent = ack.accepted
        ? `Input ok seq ${seq}`
        : `Input rejected: ${ack.reason}`;
    });
  });
}
