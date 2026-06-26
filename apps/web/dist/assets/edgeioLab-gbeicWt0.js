import{e as c}from"./gamepad-CNxKBMMt.js";const n={thrustAsSpecial:!1};function d(r,u,s=n){const e={...r,wearableGesture:u};switch(u){case"swipeL":return{...e,left:!0,dodge:!0};case"swipeR":return{...e,right:!0,dodge:!0};case"swipeU":return{...e,up:!0,jump:!0};case"swipeD":return{...e,down:!0,shield:!0};case"thrust":return s.thrustAsSpecial?{...e,special:!0}:{...e,attack:!0};case"tap":return{...e,attack:!0};case"doubleTap":return{...e,special:!0};case"block":return{...e,shield:!0};case"shake":return{...e,grab:!0};default:return e}}function l(r){var o,i;r.innerHTML=`
    <div class="shell-panel">
      <button id="shell-back" type="button">← Home</button>
      <h2>Edge-IO Lab</h2>
      <p>Map wearable gestures into the shared <code>InputFrame</code> model. Hardware is optional — use buttons to simulate gestures.</p>
      <div class="edgeio-buttons">
        ${["swipeL","swipeR","swipeU","swipeD","thrust","tap","doubleTap","block","shake"].map(t=>`<button type="button" data-gesture="${t}">${t}</button>`).join("")}
      </div>
      <pre id="edgeio-output" class="shell-pre"></pre>
    </div>
  `;const u=r.querySelector("#edgeio-output");let s;(o=r.querySelector("#shell-back"))==null||o.addEventListener("click",()=>{window.dispatchEvent(new CustomEvent("aa:navigate-home"))}),(i=r.querySelector(".edgeio-buttons"))==null||i.addEventListener("click",t=>{const a=t.target.closest("button");a!=null&&a.dataset.gesture&&(s=a.dataset.gesture,e())});const e=()=>{let t=c(0,0);s&&(t=d(t,s,n)),u.textContent=[`config: ${JSON.stringify(n)}`,`simulated gesture: ${s??"(none)"}`,`mapped input: ${JSON.stringify(t,null,2)}`,"","See packages/edgeio and docs/EDGE_IO_PROTOCOL.md for binary protocol."].join(`
`)};e()}export{l as mountEdgeIOLab};
