import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";
import {
  DEFAULT_GODOT_VERSION,
  godotExportTemplatesDir,
  resolveGodotBin,
  templatesInstalled,
  validateGodotExportDir,
} from "./godot-export-shared.mjs";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotDir = path.join(repoRoot, "game/godot");

// Public Pages path layout:
//   /godot/index.html              = stable boot shell with timeout/error UX
//   /godot/rescue-runtime.js       = playable emergency fallback, never a blank screen
//   /godot/runtime/index.html      = raw Godot web export
//   /godot/runtime/index.wasm/.pck = raw Godot engine/project payloads
const godotPublicRoot = path.join(repoRoot, "apps/web/public/godot");
const runtimeExportDir = path.join(godotPublicRoot, "runtime");
const runtimeExportIndex = path.join(runtimeExportDir, "index.html");
const bootShellIndex = path.join(godotPublicRoot, "index.html");
const rescueRuntimePath = path.join(godotPublicRoot, "rescue-runtime.js");

function clearGodotPublicRoot() {
  fs.rmSync(godotPublicRoot, { recursive: true, force: true });
  fs.mkdirSync(runtimeExportDir, { recursive: true });
}

function installTemplates(godotBin, version) {
  if (templatesInstalled(version)) {
    console.log(`Godot export templates already installed for ${version}.stable`);
    return;
  }
  console.warn(
    `Export templates for ${version}.stable not found at ${godotExportTemplatesDir(version)}.`
  );
  console.warn("Install via Godot Editor → Manage Export Templates, or run scripts/install-godot-templates.sh");
}

function patchRuntimeIndexForPages(indexPath) {
  let html = fs.readFileSync(indexPath, "utf8");

  // GitHub Pages cannot provide COOP/COEP headers. Threads are disabled in the export preset,
  // so the runtime should not insist on cross-origin isolation.
  html = html.replace('"ensureCrossOriginIsolationHeaders":true', '"ensureCrossOriginIsolationHeaders":false');

  // Let the outer boot shell know whether Godot actually started or failed.
  html = html.replace(
    "setStatusMode('hidden');",
    "setStatusMode('hidden');\n\t\t\twindow.parent?.postMessage({ type: 'aa:godot-ready' }, '*');"
  );
  html = html.replace(
    "function displayFailureNotice(err) {",
    "function displayFailureNotice(err) {\n\t\ttry { window.parent?.postMessage({ type: 'aa:godot-error', message: String(err && err.message ? err.message : err) }, '*'); } catch (_) {}"
  );

  fs.writeFileSync(indexPath, html);
}

function writeBootShell() {
  const html = String.raw`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Anime Aggressors — Godot Combat Runtime</title>
  <style>
    :root { color-scheme: dark; }
    html, body { margin: 0; width: 100%; height: 100%; overflow: hidden; background: #080816; color: #f7f7ff; font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
    #shell { position: fixed; inset: 0; display: grid; grid-template-rows: auto 1fr; background: radial-gradient(circle at 28% 18%, rgba(255, 106, 42, 0.22), transparent 28%), radial-gradient(circle at 78% 25%, rgba(118, 68, 255, 0.28), transparent 34%), linear-gradient(135deg, #090914, #141432 48%, #111122); }
    #topbar { min-height: 52px; display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 10px 18px; border-bottom: 1px solid rgba(91, 224, 255, 0.22); background: rgba(7, 7, 18, 0.7); backdrop-filter: blur(10px); }
    #brand { display: flex; flex-direction: column; line-height: 1.05; }
    #brand strong { letter-spacing: 0.09em; font-size: 14px; }
    #brand span { color: #99a2d6; font-size: 11px; margin-top: 4px; }
    #actions { display: flex; gap: 8px; align-items: center; }
    button, a.button { appearance: none; border: 1px solid rgba(87, 220, 255, 0.55); border-radius: 9px; background: rgba(20, 20, 44, 0.88); color: #f7f7ff; padding: 8px 11px; font-weight: 800; font-size: 12px; text-decoration: none; cursor: pointer; }
    button.primary { border-color: #ff8b47; background: linear-gradient(180deg, #ff7a36, #e95122); box-shadow: 0 0 22px rgba(255, 106, 42, 0.35); }
    #runtime-wrap { position: relative; min-height: 0; }
    iframe { position: absolute; inset: 0; width: 100%; height: 100%; border: 0; background: #080816; }
    #overlay { position: absolute; inset: 0; display: grid; place-items: center; padding: 24px; pointer-events: none; background: radial-gradient(circle at center, rgba(15, 15, 35, 0.10), rgba(5, 5, 14, 0.42)); }
    #panel { width: min(760px, calc(100vw - 48px)); border: 1px solid rgba(91, 224, 255, 0.28); border-radius: 18px; padding: 24px; background: rgba(12, 12, 28, 0.88); box-shadow: 0 24px 80px rgba(0, 0, 0, 0.45); pointer-events: auto; }
    #panel h1 { margin: 0 0 8px; font-size: clamp(28px, 5vw, 56px); letter-spacing: 0.03em; }
    #panel p { margin: 8px 0; color: #c6c9ec; max-width: 62ch; }
    #status { color: #5be0ff; font-weight: 900; letter-spacing: 0.08em; text-transform: uppercase; font-size: 12px; margin-bottom: 8px; }
    #progress { margin-top: 18px; height: 10px; border-radius: 999px; background: rgba(255, 255, 255, 0.1); overflow: hidden; }
    #progress > div { height: 100%; width: 38%; border-radius: 999px; background: linear-gradient(90deg, #ff6a2a, #ffd05a, #5be0ff); animation: pulse 1.2s ease-in-out infinite alternate; }
    #fallback { display: none; margin-top: 18px; gap: 10px; flex-wrap: wrap; }
    #fallback.visible { display: flex; }
    #details { margin-top: 12px; color: #9aa0c3; font-size: 12px; white-space: pre-wrap; }
    @keyframes pulse { from { transform: translateX(-28%); } to { transform: translateX(190%); } }
  </style>
</head>
<body>
  <div id="shell">
    <header id="topbar">
      <div id="brand"><strong>ANIME AGGRESSORS</strong><span>Godot combat runtime boot shell</span></div>
      <div id="actions">
        <button id="reload">Reload Runtime</button>
        <button id="rescue" class="primary">Launch Rescue Runtime</button>
      </div>
    </header>
    <main id="runtime-wrap">
      <iframe id="runtime" title="Anime Aggressors Godot Runtime" src="runtime/index.html"></iframe>
      <div id="overlay">
        <section id="panel">
          <div id="status">Booting Godot runtime</div>
          <h1>Entering the Arena</h1>
          <p>The game is loading the Godot Web runtime, project package, and combat scene. If the engine fails to report ready, the page will expose a playable rescue runtime instead of leaving you on a blank gradient.</p>
          <div id="progress"><div></div></div>
          <div id="fallback">
            <button id="fallback-rescue" class="primary">Launch Rescue Combat Runtime</button>
            <button id="fallback-open">Open Raw Godot Export</button>
          </div>
          <div id="details"></div>
        </section>
      </div>
    </main>
  </div>
  <script src="rescue-runtime.js"></script>
  <script>
    const frame = document.getElementById('runtime');
    const overlay = document.getElementById('overlay');
    const status = document.getElementById('status');
    const details = document.getElementById('details');
    const fallback = document.getElementById('fallback');
    let ready = false;
    let timedOut = false;

    function showFallback(message) {
      if (ready) return;
      timedOut = true;
      status.textContent = 'Runtime did not report ready';
      details.textContent = message;
      fallback.classList.add('visible');
    }

    function launchRescue() {
      ready = true;
      overlay.remove();
      frame.remove();
      window.AARescueRuntime?.mount(document.getElementById('runtime-wrap'));
    }

    window.addEventListener('message', (event) => {
      if (!event.data || typeof event.data !== 'object') return;
      if (event.data.type === 'aa:godot-ready') {
        ready = true;
        overlay.remove();
      }
      if (event.data.type === 'aa:godot-error') {
        showFallback('Godot error: ' + (event.data.message || 'unknown error'));
      }
    });

    document.getElementById('reload').addEventListener('click', () => {
      window.location.reload();
    });
    document.getElementById('rescue').addEventListener('click', launchRescue);
    document.getElementById('fallback-rescue').addEventListener('click', launchRescue);
    document.getElementById('fallback-open').addEventListener('click', () => {
      window.open('runtime/index.html', '_blank', 'noopener');
    });

    setTimeout(() => {
      if (!ready) {
        showFallback('The raw Godot export is still showing the splash/gradient after 12 seconds. This usually means the WebAssembly runtime, .pck package, or Godot scene failed to initialize in the browser. Use the rescue runtime now while the Godot boot error is investigated.');
      }
    }, 12000);
  </script>
</body>
</html>`;
  fs.writeFileSync(bootShellIndex, html);
}

function writeRescueRuntime() {
  const js = String.raw`(() => {
  const fighters = [
    { id: 'ember', name: 'Ember Vale', color: '#ff5b2d', aura: '#ff9a42' },
    { id: 'juno', name: 'Juno Spark', color: '#ffd93a', aura: '#fff17c' },
  ];

  function mount(root) {
    root.innerHTML = '';
    const canvas = document.createElement('canvas');
    canvas.width = 1280;
    canvas.height = 720;
    canvas.style.width = '100%';
    canvas.style.height = '100%';
    canvas.style.display = 'block';
    canvas.style.background = '#080816';
    root.appendChild(canvas);
    const ctx = canvas.getContext('2d');
    const keys = new Set();
    const players = [
      makePlayer(260, fighters[0], { left: 'KeyA', right: 'KeyD', jump: 'KeyW', jump2: 'Space', attack: 'KeyJ', charge: 'KeyF' }),
      makePlayer(930, fighters[1], { left: 'ArrowLeft', right: 'ArrowRight', jump: 'ArrowUp', jump2: 'Numpad0', attack: 'Numpad1', charge: 'Slash' }),
    ];
    let hitFlash = 0;

    function makePlayer(x, fighter, controls) {
      return { x, y: 470, vx: 0, vy: 0, w: 42, h: 92, face: 1, jumps: 0, grounded: true, attack: 0, hitstun: 0, damage: 0, aura: 0, charging: false, fighter, controls };
    }

    window.addEventListener('keydown', (e) => { keys.add(e.code); if (['Space','ArrowUp','ArrowDown','ArrowLeft','ArrowRight'].includes(e.code)) e.preventDefault(); });
    window.addEventListener('keyup', (e) => keys.delete(e.code));

    function stepPlayer(p, other) {
      const c = p.controls;
      const left = keys.has(c.left);
      const right = keys.has(c.right);
      const jump = keys.has(c.jump) || keys.has(c.jump2);
      const attack = keys.has(c.attack);
      p.charging = keys.has(c.charge);

      if (p.hitstun > 0) p.hitstun--;
      if (p.attack > 0) p.attack--;
      if (p.charging) p.aura = Math.min(100, p.aura + 0.7);

      if (p.hitstun <= 0) {
        const accel = p.grounded ? 1.5 : 0.82;
        if (left) { p.vx -= accel; p.face = -1; }
        if (right) { p.vx += accel; p.face = 1; }
        if (!left && !right && p.grounded) p.vx *= 0.78;
        p.vx = Math.max(-9, Math.min(9, p.vx));
        if (jump && !p._jumpHeld && (p.grounded || p.jumps < 2)) {
          p.vy = p.grounded ? -24 : -21;
          p.grounded = false;
          p.jumps++;
        }
        if (attack && p.attack <= 0) p.attack = 16;
      }
      p._jumpHeld = jump;

      p.vy += 1.05;
      p.x += p.vx;
      p.y += p.vy;
      if (p.y >= 470) { p.y = 470; p.vy = 0; p.grounded = true; p.jumps = 0; }
      if (p.x < 80) { p.x = 80; p.vx = 0; }
      if (p.x > 1200) { p.x = 1200; p.vx = 0; }

      if (p.attack === 8) {
        const hx = p.x + p.face * 64;
        if (Math.abs(hx - other.x) < 70 && Math.abs(p.y - other.y) < 95) {
          other.damage += 8;
          other.hitstun = 12;
          other.vx = p.face * (8 + other.damage * 0.06);
          other.vy = -9 - other.damage * 0.025;
          hitFlash = 8;
        }
      }
    }

    function drawFighter(p) {
      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.scale(p.face, 1);
      if (p.aura > 5) {
        ctx.globalAlpha = 0.28 + 0.25 * Math.sin(performance.now() / 80);
        ctx.strokeStyle = p.fighter.aura;
        ctx.lineWidth = 5;
        ctx.beginPath(); ctx.ellipse(0, -46, 54 + p.aura * 0.25, 76 + p.aura * 0.25, 0, 0, Math.PI * 2); ctx.stroke();
        ctx.globalAlpha = 1;
      }
      ctx.fillStyle = 'rgba(0,0,0,0.35)'; ctx.beginPath(); ctx.ellipse(0, 14, 46, 10, 0, 0, Math.PI * 2); ctx.fill();
      const recoil = p.hitstun > 0 ? -0.35 : 0;
      ctx.rotate(recoil);
      ctx.fillStyle = p.fighter.color;
      ctx.fillRect(-22, -78, 44, 58);
      ctx.beginPath(); ctx.arc(0, -96, 20, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = '#111225';
      ctx.fillRect(-19, -20, 15, 42); ctx.fillRect(4, -20, 15, 42);
      const swing = p.attack > 0 ? Math.sin((16 - p.attack) / 16 * Math.PI) : 0;
      ctx.strokeStyle = p.fighter.color; ctx.lineWidth = 12; ctx.lineCap = 'round';
      ctx.beginPath(); ctx.moveTo(20, -66); ctx.lineTo(54 + swing * 48, -62 + swing * 10); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(-20, -66); ctx.lineTo(-42, -48); ctx.stroke();
      if (p.attack > 0) { ctx.strokeStyle = p.fighter.aura; ctx.lineWidth = 4; ctx.beginPath(); ctx.arc(70, -60, 34, -0.9, 0.9); ctx.stroke(); }
      ctx.restore();
    }

    function draw() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      const g = ctx.createLinearGradient(0, 0, 0, canvas.height); g.addColorStop(0, '#16163b'); g.addColorStop(1, '#070814'); ctx.fillStyle = g; ctx.fillRect(0, 0, canvas.width, canvas.height);
      ctx.fillStyle = '#2fe0d3'; ctx.fillRect(70, 500, 1140, 28); ctx.fillStyle = '#ff456d'; ctx.fillRect(70, 492, 1140, 10);
      if (hitFlash > 0) { ctx.globalAlpha = hitFlash / 12; ctx.fillStyle = '#ffffff'; ctx.fillRect(0, 0, canvas.width, canvas.height); ctx.globalAlpha = 1; hitFlash--; }
      players.forEach((p, i) => { ctx.fillStyle = '#fff'; ctx.font = '18px Inter, sans-serif'; ctx.fillText(`${p.fighter.name} ${Math.round(p.damage)}% Aura ${Math.round(p.aura)}%`, i === 0 ? 32 : 850, 42); });
      drawFighter(players[0]); drawFighter(players[1]);
      ctx.fillStyle = '#9aa0c3'; ctx.font = '14px Inter, sans-serif'; ctx.fillText('RESCUE RUNTIME: P1 A/D W/Space J F · P2 arrows/Numpad0 Numpad1 /', 32, 690);
    }

    function loop() {
      stepPlayer(players[0], players[1]); stepPlayer(players[1], players[0]); draw(); requestAnimationFrame(loop);
    }
    loop();
  }

  window.AARescueRuntime = { mount };
})();`;
  fs.writeFileSync(rescueRuntimePath, js);
}

const godotBin = resolveGodotBin();
if (!godotBin) {
  console.error("Godot CLI was not found.");
  console.error("Install Godot 4.3+ or set GODOT_BIN=/path/to/godot");
  console.error("Then run: npm run godot:export:web");
  process.exit(1);
}

let version = DEFAULT_GODOT_VERSION;
try {
  const verOut = execSync(`"${godotBin}" --version`, { encoding: "utf8" }).trim();
  console.log("Using Godot:", verOut);
  const match = verOut.match(/^(\d+\.\d+(?:\.\d+)?)/);
  if (match) {
    version = match[1];
  }
} catch {
  console.log("Using configured Godot version:", version);
}

clearGodotPublicRoot();
installTemplates(godotBin, version);

try {
  execSync(
    `"${godotBin}" --headless --path "${godotDir}" --export-release "Web" "${runtimeExportIndex}"`,
    { stdio: "inherit", cwd: repoRoot }
  );
} catch (error) {
  console.error("Godot export failed:", error.message ?? error);
  process.exit(1);
}

patchRuntimeIndexForPages(runtimeExportIndex);
writeRescueRuntime();
writeBootShell();

const result = validateGodotExportDir(runtimeExportDir, { label: runtimeExportDir });
if (!result.ok) {
  console.error("Export completed but runtime output is invalid:");
  for (const err of result.errors) {
    console.error(`  - ${err}`);
  }
  process.exit(1);
}

console.log("Exported Godot Web runtime to", runtimeExportDir);
console.log("Wrote Godot boot shell to", bootShellIndex);
console.log("  runtime files:", result.files.all.join(", "));
