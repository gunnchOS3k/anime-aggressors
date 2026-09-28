/**
 * Phone/browser controller surface for Party Mode (Jackbox-like join).
 * Served by LAN host; does not require installing the full game.
 */

export type ControllerSurfaceKind = "player" | "spectator";

export function renderBrowserControllerHtml(opts: {
  gameId: "anime-aggressors" | "pedestrian-pursuit";
  code?: string;
  joinBasePath?: string;
}): string {
  const game = opts.gameId;
  const prefill = opts.code ?? "";
  const api = opts.joinBasePath ?? "";
  const combatPad =
    game === "anime-aggressors"
      ? `
    <div class="pad" id="combat-pad">
      <button data-act="left">←</button>
      <button data-act="right">→</button>
      <button data-act="up">↑</button>
      <button data-act="down">↓</button>
      <button data-act="jump">Jump</button>
      <button data-act="attack">Attack</button>
      <button data-act="special">Special</button>
      <button data-act="shield">Shield</button>
      <button data-act="dodge">Dodge</button>
      <button data-act="pause">Pause</button>
    </div>`
      : `
    <div class="pad" id="combat-pad">
      <button data-act="steerLeft">Steer L</button>
      <button data-act="steerRight">Steer R</button>
      <button data-act="accel">Accel</button>
      <button data-act="brake">Brake</button>
      <button data-act="boost">Boost</button>
      <button data-act="trick">Trick</button>
      <label class="a11y"><input type="checkbox" id="auto-accel"/> Auto-accel</label>
    </div>`;

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"/>
<title>PartyLink Controller — ${game}</title>
<style>
  :root { color-scheme: dark; --bg:#0b1020; --fg:#f4f7ff; --accent:#5eead4; --muted:#8b95b0; }
  * { box-sizing: border-box; }
  body { margin:0; font-family: ui-sans-serif, system-ui, sans-serif; background:linear-gradient(160deg,#0b1020,#152040); color:var(--fg); min-height:100vh; padding:1rem; }
  h1 { font-size:1.15rem; margin:0 0 .5rem; letter-spacing:.04em; }
  .card { background:rgba(255,255,255,.06); border:1px solid rgba(255,255,255,.12); border-radius:14px; padding:1rem; margin-bottom:1rem; }
  label { display:block; font-size:.8rem; color:var(--muted); margin:.5rem 0 .2rem; }
  input, select, button { font:inherit; }
  input, select { width:100%; padding:.65rem .75rem; border-radius:10px; border:1px solid rgba(255,255,255,.18); background:#0f172a; color:var(--fg); }
  button { padding:.7rem .9rem; border-radius:12px; border:0; background:var(--accent); color:#042f2e; font-weight:700; cursor:pointer; }
  button.secondary { background:rgba(255,255,255,.12); color:var(--fg); }
  .pad { display:grid; grid-template-columns:repeat(3,1fr); gap:.5rem; margin-top:.75rem; }
  .pad button { min-height:3rem; background:#1e293b; color:var(--fg); }
  .pad button:active { background:#334155; }
  #qos { font-size:.75rem; color:var(--muted); }
  #status { font-weight:600; color:var(--accent); }
  .hidden { display:none !important; }
</style>
</head>
<body>
  <h1>PartyLink Controller</h1>
  <p id="status">Not connected</p>
  <p id="qos">RTT: —</p>

  <div class="card" id="join-card">
    <label>Room code<input id="code" value="${prefill}" autocomplete="off" autocapitalize="characters" maxlength="8"/></label>
    <label>Display name<input id="name" value="Player" maxlength="24"/></label>
    <label>Role
      <select id="role">
        <option value="PLAYER">PLAYER</option>
        <option value="SPECTATOR">SPECTATOR</option>
      </select>
    </label>
    <button id="join-btn" type="button">Join room</button>
  </div>

  <div class="card hidden" id="lobby-card">
    <label>Fighter / Racer ID<input id="fighter" value="ember"/></label>
    <label>Team
      <select id="team">
        <option value="FFA">FFA</option>
        <option value="0">Team A / 0</option>
        <option value="1">Team B / 1</option>
        <option value="2">Team C / 2</option>
        <option value="3">Team D / 3</option>
      </select>
    </label>
    <button id="ready-btn" type="button">Ready</button>
    <button id="reconnect-btn" class="secondary" type="button">Reconnect</button>
  </div>

  <div class="card hidden" id="play-card">
    ${combatPad}
  </div>

<script>
const API = ${JSON.stringify(api)};
const GAME = ${JSON.stringify(game)};
let session = null;
let seq = 0;
let held = {};
const statusEl = document.getElementById('status');
const qosEl = document.getElementById('qos');

function setStatus(t){ statusEl.textContent = t; }

async function api(path, body){
  const t0 = performance.now();
  const res = await fetch(API + path, {
    method: 'POST',
    headers: {'content-type':'application/json'},
    body: JSON.stringify(body)
  });
  const rtt = Math.round(performance.now() - t0);
  qosEl.textContent = 'RTT: ' + rtt + ' ms · LAN join (no public relay)';
  return res.json();
}

document.getElementById('join-btn').onclick = async () => {
  const code = document.getElementById('code').value.trim().toUpperCase();
  const displayName = document.getElementById('name').value.trim() || 'Player';
  const role = document.getElementById('role').value;
  const out = await api('/join', { code, displayName, role, gameId: GAME });
  if (!out.ok) { setStatus('Join failed: ' + (out.reason||'error')); return; }
  session = out;
  localStorage.setItem('partylink.resume.'+GAME, JSON.stringify({ code, token: out.participant.token }));
  setStatus(role + ' · seat ' + (out.participant.seatIndex ?? '—') + ' · ' + code);
  document.getElementById('join-card').classList.add('hidden');
  document.getElementById('lobby-card').classList.remove('hidden');
  if (role === 'SPECTATOR') {
    document.getElementById('ready-btn').classList.add('hidden');
    document.getElementById('play-card').classList.add('hidden');
    setStatus('SPECTATOR watching · no gameplay input');
  }
};

document.getElementById('ready-btn').onclick = async () => {
  if (!session) return;
  const fighterId = document.getElementById('fighter').value.trim() || 'ember';
  await api('/fighter', { participantId: session.participant.id, token: session.participant.token, fighterId });
  const teamRaw = document.getElementById('team').value;
  await api('/team', { participantId: session.participant.id, token: session.participant.token, team: teamRaw });
  const ready = await api('/ready', { participantId: session.participant.id, token: session.participant.token, ready: true });
  if (!ready.ok) { setStatus('Ready failed: ' + (ready.reason||'')); return; }
  setStatus('READY · waiting for host');
  document.getElementById('play-card').classList.remove('hidden');
};

document.getElementById('reconnect-btn').onclick = async () => {
  const raw = localStorage.getItem('partylink.resume.'+GAME);
  if (!raw) { setStatus('No reconnect token'); return; }
  const saved = JSON.parse(raw);
  const out = await api('/reconnect', { code: saved.code, token: saved.token });
  if (!out.ok) { setStatus('Reconnect failed: ' + (out.reason||'')); return; }
  session = out;
  setStatus('Reconnected · seat ' + (out.participant.seatIndex ?? '—'));
  document.getElementById('join-card').classList.add('hidden');
  document.getElementById('lobby-card').classList.remove('hidden');
  document.getElementById('play-card').classList.remove('hidden');
};

function sendInput(semantic){
  if (!session || session.participant.role === 'SPECTATOR') return;
  seq += 1;
  api('/input', {
    participantId: session.participant.id,
    token: session.participant.token,
    seatIndex: session.participant.seatIndex,
    sequence: seq,
    tick: seq,
    semantic,
    clientMs: Date.now()
  }).catch(()=>{});
}

document.querySelectorAll('#combat-pad button').forEach((btn) => {
  const act = btn.getAttribute('data-act');
  const down = () => { held[act] = true; const s={}; s[act]=true; sendInput(s); };
  const up = () => { held[act] = false; sendInput({ [act]: false }); };
  btn.addEventListener('pointerdown', (e) => { e.preventDefault(); down(); });
  btn.addEventListener('pointerup', (e) => { e.preventDefault(); up(); });
  btn.addEventListener('pointerleave', up);
});

const auto = document.getElementById('auto-accel');
if (auto) auto.onchange = () => sendInput({ autoAccel: auto.checked });
</script>
</body>
</html>`;
}
