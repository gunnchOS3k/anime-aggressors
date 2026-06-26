import{c as p,R as k,d as g,h as d}from"./rollbackSession-BdevqEGe.js";function R(t){var s,n;t.innerHTML=`
    <div class="shell-panel">
      <button id="shell-back" type="button">← Home</button>
      <h2>Rollback Debug</h2>
      <p>Runs a deterministic replay with injected late inputs to exercise rollback snapshots.</p>
      <button id="run-rollback" type="button" class="btn-primary">Run rollback scenario</button>
      <pre id="rollback-output" class="shell-pre"></pre>
    </div>
  `;const f=t.querySelector("#rollback-output");(s=t.querySelector("#shell-back"))==null||s.addEventListener("click",()=>{window.dispatchEvent(new CustomEvent("aa:navigate-home"))}),(n=t.querySelector("#run-rollback"))==null||n.addEventListener("click",()=>{const o={playerCount:2,stocks:3,matchDurationFrames:10800,stageId:"skyline-arena",characterIds:["ember","tide"],seed:42};let a=p(o);const r=[],l=new k(a,{snapshotInterval:1,maxRollbackFrames:120,playerCount:2});let c=0;for(let e=0;e<120;e++){const u=[{frame:e,playerId:0,left:e%20<10,right:!1,up:!1,down:!1,jump:e===30,attack:e===45,special:!1,shield:!1,dodge:!1,grab:!1},{frame:e,playerId:1,left:!1,right:e%15<8,up:!1,down:!1,jump:!1,attack:e===50,special:!1,shield:!1,dodge:!1,grab:!1}];r.push(u);const h=l.getRollbackCount();a=l.advanceFrame(u,[!0,!0]),l.getRollbackCount()>h&&(c=l.getRollbackCount())}const b=p(o),i=g(b,r),m=d(a)===i.finalHash;f.textContent=["frames simulated: 120",`rollback count: ${c}`,`final hash (session): ${d(a)}`,`final hash (replay):  ${i.finalHash}`,`determinism match: ${m?"PASS":"FAIL"}`,`P1 damage: ${a.players[0].damage}%`,`P2 damage: ${a.players[1].damage}%`].join(`
`)})}export{R as mountRollbackDebug};
