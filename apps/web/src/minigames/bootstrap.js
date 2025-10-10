import { startHomeRun } from './homeRun';
import { startPaintFloor } from './paintFloor';
import { startLaneBlaster } from './laneBlaster';
export function bootstrapMiniGames(root) {
    if (!root)
        return;
    root.innerHTML = `
    <div class="mini-menu">
      <button data-game="home">🏏 Home-Run Sandbag</button>
      <button data-game="paint">🎨 Paint the Floor</button>
      <button data-game="lane">🚀 4-Lane Blaster</button>
      <span class="hint">Plug 2 controllers or share 1. Keyboard works too.</span>
    </div>
    <canvas id="stage" width="960" height="540"></canvas>
  `;
    const stage = root.querySelector('#stage');
    root.addEventListener('click', (e) => {
        const b = e.target.closest('button');
        if (!b)
            return;
        const game = b.dataset.game;
        stage.style.display = 'block';
        if (game === 'home')
            startHomeRun(stage);
        if (game === 'paint')
            startPaintFloor(stage);
        if (game === 'lane')
            startLaneBlaster(stage);
    });
}
