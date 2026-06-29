import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";
import { resolveGodotBin, validateGodotExportDir } from "./godot-export-shared.mjs";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const godotDir = path.join(repoRoot, "game/godot");
const publicRoot = path.join(repoRoot, "apps/web/public/godot");
const runtimeDir = path.join(publicRoot, "runtime");
const runtimeIndex = path.join(runtimeDir, "index.html");
const bootIndex = path.join(publicRoot, "index.html");
const rescueJs = path.join(publicRoot, "rescue-runtime.js");

function resetOutput() {
  fs.rmSync(publicRoot, { recursive: true, force: true });
  fs.mkdirSync(runtimeDir, { recursive: true });
}

function patchGodotHtml() {
  let html = fs.readFileSync(runtimeIndex, "utf8");
  html = html.replace('"ensureCrossOriginIsolationHeaders":true', '"ensureCrossOriginIsolationHeaders":false');
  html = html.replace(
    "setStatusMode('hidden');",
    "setStatusMode('hidden');\nwindow.parent && window.parent.postMessage({ type: 'aa:godot-ready' }, '*');"
  );
  html = html.replace(
    "function displayFailureNotice(err) {",
    "function displayFailureNotice(err) {\ntry { window.parent && window.parent.postMessage({ type: 'aa:godot-error', message: String(err && err.message ? err.message : err) }, '*'); } catch (_) {}"
  );
  fs.writeFileSync(runtimeIndex, html);
}

function writeBootShell() {
  const html = [
    "<!doctype html>",
    '<html lang="en">',
    "<head>",
    '<meta charset="utf-8" />',
    '<meta name="viewport" content="width=device-width, initial-scale=1" />',
    "<title>Anime Aggressors — Godot Runtime</title>",
    "<style>",
    "html,body{margin:0;width:100%;height:100%;overflow:hidden;background:#080816;color:#f7f7ff;font-family:Inter,system-ui,sans-serif}",
    "#wrap{position:fixed;inset:0;display:grid;grid-template-rows:auto 1fr;background:radial-gradient(circle at 28% 18%,rgba(255,106,42,.22),transparent 28%),radial-gradient(circle at 78% 25%,rgba(118,68,255,.28),transparent 34%),linear-gradient(135deg,#090914,#141432 48%,#111122)}",
    "#bar{min-height:52px;display:flex;justify-content:space-between;align-items:center;padding:10px 18px;border-bottom:1px solid rgba(91,224,255,.22);background:rgba(7,7,18,.7)}",
    "button{border:1px solid rgba(87,220,255,.55);border-radius:9px;background:rgba(20,20,44,.88);color:#fff;padding:8px 11px;font-weight:800;cursor:pointer}.primary{border-color:#ff8b47;background:linear-gradient(180deg,#ff7a36,#e95122)}",
    "#stage{position:relative;min-height:0}iframe{position:absolute;inset:0;width:100%;height:100%;border:0;background:#080816}#overlay{position:absolute;inset:0;display:grid;place-items:center;padding:24px;background:rgba(5,5,14,.42)}",
    "#panel{width:min(760px,calc(100vw - 48px));border:1px solid rgba(91,224,255,.28);border-radius:18px;padding:24px;background:rgba(12,12,28,.9);box-shadow:0 24px 80px rgba(0,0,0,.45)}h1{margin:0 0 8px;font-size:clamp(28px,5vw,56px)}p{color:#c6c9ec}#fallback{display:none;gap:10px;flex-wrap:wrap;margin-top:18px}#fallback.visible{display:flex}#details{margin-top:12px;color:#9aa0c3;font-size:12px;white-space:pre-wrap}",
    "</style>",
    "</head>",
    "<body>",
    '<div id="wrap"><header id="bar"><strong>ANIME AGGRESSORS — GODOT RUNTIME</strong><div><button id="reload">Reload</button> <button id="rescue" class="primary">Launch Rescue Runtime</button></div></header><main id="stage"><iframe id="runtime" title="Anime Aggressors Godot Runtime" src="runtime/index.html"></iframe><div id="overlay"><section id="panel"><div id="status">Booting Godot runtime</div><h1>Entering the Arena</h1><p>The Godot Web runtime is loading. If it hangs, this shell exposes a playable rescue runtime instead of a blank gradient.</p><div id="fallback"><button id="fallback-rescue" class="primary">Launch Rescue Combat Runtime</button><button id="fallback-open">Open Raw Export</button></div><div id="details"></div></section></div></main></div>',
    '<script src="rescue-runtime.js"></script>',
    "<script>",
    "const frame=document.getElementById('runtime'),overlay=document.getElementById('overlay'),statusEl=document.getElementById('status'),details=document.getElementById('details'),fallback=document.getElementById('fallback');let ready=false;function showFallback(m){if(ready)return;statusEl.textContent='Runtime did not report ready';details.textContent=m;fallback.classList.add('visible')}function launchRescue(){ready=true;overlay.remove();frame.remove();window.AARescueRuntime&&window.AARescueRuntime.mount(document.getElementById('stage'))}window.addEventListener('message',e=>{if(!e.data||typeof e.data!=='object')return;if(e.data.type==='aa:godot-ready'){ready=true;overlay.remove()}if(e.data.type==='aa:godot-error')showFallback('Godot error: '+(e.data.message||'unknown error'))});document.getElementById('reload').onclick=()=>location.reload();document.getElementById('rescue').onclick=launchRescue;document.getElementById('fallback-rescue').onclick=launchRescue;document.getElementById('fallback-open').onclick=()=>window.open('runtime/index.html','_blank','noopener');setTimeout(()=>showFallback('The raw Godot export stayed on the splash/gradient for 12 seconds. Use rescue runtime now while the Godot boot error is investigated.'),12000);",
    "</script>",
    "</body>",
    "</html>",
  ].join("\n");
  fs.writeFileSync(bootIndex, html);
}

function writeRescueRuntime() {
  const js = [
    "(()=>{",
    "function mount(root){root.innerHTML='';const c=document.createElement('canvas');c.width=1280;c.height=720;c.style.width='100%';c.style.height='100%';c.style.display='block';root.appendChild(c);const x=c.getContext('2d');const keys=new Set();const fs=[{name:'Ember Vale',color:'#ff5b2d',aura:'#ff9a42'},{name:'Juno Spark',color:'#ffd93a',aura:'#fff17c'}];function p(px,f,ctl){return{x:px,y:470,vx:0,vy:0,face:1,jumps:0,grounded:true,attack:0,hitstun:0,damage:0,aura:0,fighter:f,ctl:ctl}}const ps=[p(260,fs[0],{l:'KeyA',r:'KeyD',j:'KeyW',j2:'Space',a:'KeyJ',ch:'KeyF'}),p(930,fs[1],{l:'ArrowLeft',r:'ArrowRight',j:'ArrowUp',j2:'Numpad0',a:'Numpad1',ch:'Slash'})];let flash=0;addEventListener('keydown',e=>{keys.add(e.code);if(['Space','ArrowUp','ArrowDown','ArrowLeft','ArrowRight'].includes(e.code))e.preventDefault()});addEventListener('keyup',e=>keys.delete(e.code));function step(a,b){const ct=a.ctl,j=keys.has(ct.j)||keys.has(ct.j2);if(a.hitstun>0)a.hitstun--;if(a.attack>0)a.attack--;if(keys.has(ct.ch))a.aura=Math.min(100,a.aura+.7);if(a.hitstun<=0){const ac=a.grounded?1.5:.82;if(keys.has(ct.l)){a.vx-=ac;a.face=-1}if(keys.has(ct.r)){a.vx+=ac;a.face=1}if(!keys.has(ct.l)&&!keys.has(ct.r)&&a.grounded)a.vx*=.78;a.vx=Math.max(-9,Math.min(9,a.vx));if(j&&!a.jumpHeld&&(a.grounded||a.jumps<2)){a.vy=a.grounded?-24:-21;a.grounded=false;a.jumps++}if(keys.has(ct.a)&&a.attack<=0)a.attack=16}a.jumpHeld=j;a.vy+=1.05;a.x+=a.vx;a.y+=a.vy;if(a.y>=470){a.y=470;a.vy=0;a.grounded=true;a.jumps=0}a.x=Math.max(80,Math.min(1200,a.x));if(a.attack===8){const hx=a.x+a.face*64;if(Math.abs(hx-b.x)<70&&Math.abs(a.y-b.y)<95){b.damage+=8;b.hitstun=12;b.vx=a.face*(8+b.damage*.06);b.vy=-9-b.damage*.025;flash=8}}}",
    "function drawP(a){x.save();x.translate(a.x,a.y);x.scale(a.face,1);if(a.aura>5){x.globalAlpha=.28+.25*Math.sin(performance.now()/80);x.strokeStyle=a.fighter.aura;x.lineWidth=5;x.beginPath();x.ellipse(0,-46,54+a.aura*.25,76+a.aura*.25,0,0,Math.PI*2);x.stroke();x.globalAlpha=1}x.fillStyle='rgba(0,0,0,.35)';x.beginPath();x.ellipse(0,14,46,10,0,0,Math.PI*2);x.fill();x.rotate(a.hitstun>0?-.35:0);x.fillStyle=a.fighter.color;x.fillRect(-22,-78,44,58);x.beginPath();x.arc(0,-96,20,0,Math.PI*2);x.fill();x.fillStyle='#111225';x.fillRect(-19,-20,15,42);x.fillRect(4,-20,15,42);const s=a.attack>0?Math.sin((16-a.attack)/16*Math.PI):0;x.strokeStyle=a.fighter.color;x.lineWidth=12;x.lineCap='round';x.beginPath();x.moveTo(20,-66);x.lineTo(54+s*48,-62+s*10);x.stroke();x.beginPath();x.moveTo(-20,-66);x.lineTo(-42,-48);x.stroke();if(a.attack>0){x.strokeStyle=a.fighter.aura;x.lineWidth=4;x.beginPath();x.arc(70,-60,34,-.9,.9);x.stroke()}x.restore()}",
    "function draw(){x.clearRect(0,0,c.width,c.height);const g=x.createLinearGradient(0,0,0,c.height);g.addColorStop(0,'#16163b');g.addColorStop(1,'#070814');x.fillStyle=g;x.fillRect(0,0,c.width,c.height);x.fillStyle='#2fe0d3';x.fillRect(70,500,1140,28);x.fillStyle='#ff456d';x.fillRect(70,492,1140,10);if(flash>0){x.globalAlpha=flash/12;x.fillStyle='#fff';x.fillRect(0,0,c.width,c.height);x.globalAlpha=1;flash--}ps.forEach((a,i)=>{x.fillStyle='#fff';x.font='18px Inter, sans-serif';x.fillText(a.fighter.name+' '+Math.round(a.damage)+'% Aura '+Math.round(a.aura)+'%',i===0?32:850,42)});drawP(ps[0]);drawP(ps[1]);x.fillStyle='#9aa0c3';x.font='14px Inter, sans-serif';x.fillText('RESCUE RUNTIME: P1 A/D W/Space J F · P2 arrows/Numpad0 Numpad1 /',32,690)}function loop(){step(ps[0],ps[1]);step(ps[1],ps[0]);draw();requestAnimationFrame(loop)}loop()}",
    "window.AARescueRuntime={mount};",
    "})();",
  ].join("\n");
  fs.writeFileSync(rescueJs, js);
}

const godotBin = resolveGodotBin();
if (!godotBin) {
  console.error("Godot CLI was not found. Set GODOT_BIN or install Godot 4.3+.");
  process.exit(1);
}

resetOutput();
console.log("Using Godot:", execSync(`"${godotBin}" --version`, { encoding: "utf8" }).trim());
try {
  execSync(`"${godotBin}" --headless --path "${godotDir}" --export-release "Web" "${runtimeIndex}"`, { stdio: "inherit", cwd: repoRoot });
} catch (error) {
  console.error("Godot export failed:", error.message ?? error);
  process.exit(1);
}

patchGodotHtml();
writeBootShell();
writeRescueRuntime();

const result = validateGodotExportDir(runtimeDir, { label: runtimeDir });
if (!result.ok) {
  console.error("Godot export output invalid:");
  for (const err of result.errors) console.error("  - " + err);
  process.exit(1);
}
console.log("Godot Pages export OK:", runtimeDir);
console.log("Files:", result.files.all.join(", "));
