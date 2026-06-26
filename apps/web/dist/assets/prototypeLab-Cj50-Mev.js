import{b as a}from"./minigames-BBK2wDVi.js";import"./gamepad-CNxKBMMt.js";function i(e){var t;e.innerHTML=`
    <div class="shell-panel">
      <button id="shell-back" type="button">← Home</button>
      <h2>Prototype Lab</h2>
      <p class="shell-muted">Early mechanic experiments — not the main Anime Aggressors product.</p>
    </div>
    <div id="prototype-lab-games"></div>
  `,(t=e.querySelector("#shell-back"))==null||t.addEventListener("click",()=>{window.dispatchEvent(new CustomEvent("aa:navigate-home"))});const o=e.querySelector("#prototype-lab-games");a(o)}export{i as mountPrototypeLab};
