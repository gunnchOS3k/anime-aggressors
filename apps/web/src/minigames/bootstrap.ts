export function bootstrapMiniGames(root: HTMLElement | null) {
  if (!root) return;

  root.innerHTML = `
    <div class="mini-menu">
      <p class="hint">Prototype experiments — main product is Play Match (platform fighter).</p>
      <button data-game="paint">🎨 Paint the Floor</button>
      <button data-game="lane">🚀 4-Lane Blaster</button>
      <p class="hint">Impact Dummy Derby moved to homepage and <code>#/impact-dummy-derby</code>.</p>
    </div>
    <canvas id="stage" width="960" height="540"></canvas>
  `;

  const stage = root.querySelector("#stage") as HTMLCanvasElement;

  root.addEventListener("click", async (e) => {
    const b = (e.target as HTMLElement).closest("button");
    if (!b) return;

    const game = b.dataset.game;
    stage.style.display = "block";

    if (game === "paint") {
      const { startPaintFloor } = await import("./paintFloor.js");
      startPaintFloor(stage);
    }
    if (game === "lane") {
      const { startLaneBlaster } = await import("./laneBlaster.js");
      startLaneBlaster(stage);
    }
  });
}
