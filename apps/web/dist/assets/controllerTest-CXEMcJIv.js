import{p as u}from"./deviceAssignment-CVNF4dTW.js";import"./gamepad-CNxKBMMt.js";function m(t){var r;t.innerHTML=`
    <div class="shell-panel">
      <button id="shell-back" type="button">← Home</button>
      <h2>Controller Test</h2>
      <p>Keyboard, gamepad, and Edge-IO gesture mapping preview. Inputs are polled live — no match simulation.</p>
      <pre id="controller-output" class="shell-pre"></pre>
    </div>
  `;const a=t.querySelector("#controller-output");(r=t.querySelector("#shell-back"))==null||r.addEventListener("click",()=>{cancelAnimationFrame(l),window.dispatchEvent(new CustomEvent("aa:navigate-home"))});let n=0,l=0;const o=()=>{const s=u(n).map(e=>{const p=[e.left&&"←",e.right&&"→",e.up&&"↑",e.down&&"↓",e.jump&&"J",e.attack&&"A",e.special&&"S",e.shield&&"Sh",e.dodge&&"D",e.grab&&"G",e.wearableGesture&&`W:${e.wearableGesture}`].filter(Boolean);return`P${e.playerId+1}: ${p.join(" ")||"(idle)"}`});a.textContent=`frame ${n}
${s.join(`
`)}

P1: Arrows + ZXCVB | P2: WASD + 12345`,n+=1,l=requestAnimationFrame(o)};o()}export{m as mountControllerTest};
