import React from "react"; import { createRoot } from "react-dom/client";
function App(){ return <div style={{fontFamily:"system-ui",padding:24}}>
  <h1>Anime Aggressors</h1>
  <p>Shōnen PvP arena — web demo shell.</p>
</div>; }
createRoot(document.getElementById("root")!).render(<App/>);
TS'