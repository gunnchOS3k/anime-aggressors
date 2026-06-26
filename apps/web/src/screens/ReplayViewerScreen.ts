import { getReplay } from "../storage/replayStorage.ts";
import { ReplayPlayer } from "../replay/ReplayPlayer.ts";
import { ThreeGameRenderer } from "../renderer-three/ThreeGameRenderer.ts";
import { navigateHome } from "../router.ts";
import { APP_ROUTES } from "../routes.ts";

export async function mountReplayViewerScreen(
  root: HTMLElement,
  replayId: string,
): Promise<void> {
  const record = await getReplay(replayId);
  if (!record) {
    root.innerHTML = `<p>Replay not found. <a href="${APP_ROUTES.careerReplays}">Back to vault</a></p>`;
    return;
  }

  root.innerHTML = `
    <div class="replay-viewer">
      <header class="screen-header">
        <button type="button" id="replay-back" class="btn-tertiary">← Back</button>
        <div>
          <h1>${record.title}</h1>
          <p>${record.mode} · ${record.fighterNames.join(" vs ")} · hash <code>${record.finalStateHash}</code></p>
        </div>
      </header>
      <div id="replay-viewport" class="pf-viewport"></div>
      <div id="replay-hud" class="replay-hud"></div>
      <div class="replay-controls">
        <button type="button" id="replay-play">Play</button>
        <button type="button" id="replay-pause">Pause</button>
        <button type="button" id="replay-step">Step</button>
        <button type="button" id="replay-reset">Reset</button>
        <label>Speed
          <select id="replay-speed">
            <option value="0.5">0.5x</option>
            <option value="1" selected>1x</option>
            <option value="2">2x</option>
          </select>
        </label>
      </div>
      <div id="replay-scoreboard"></div>
    </div>
  `;

  const viewport = root.querySelector("#replay-viewport") as HTMLElement;
  const hud = root.querySelector("#replay-hud") as HTMLElement;
  const scoreboard = root.querySelector("#replay-scoreboard") as HTMLElement;

  const renderer = new ThreeGameRenderer(viewport, { smoothCamera: true });
  renderer.mount();
  renderer.resize(viewport.clientWidth || 960, viewport.clientHeight || 540);

  const player = new ReplayPlayer(
    record,
    (state, frame) => {
      renderer.update(state, { debug: false });
      renderer.render();
      hud.textContent = `Frame ${frame} / ${record.inputLog.length}`;
      scoreboard.innerHTML = `<ul>${state.players
        .map((p) => `<li>${p.fighterName}: ${p.damage}% · ${p.stocks} stocks</li>`)
        .join("")}</ul>`;
    },
    () => {
      hud.textContent += " — Complete";
    },
  );

  player.getState();
  renderer.update(player.getState(), {});
  renderer.render();

  root.querySelector("#replay-back")?.addEventListener("click", () => {
    player.dispose();
    renderer.dispose();
    navigateHome();
    window.location.hash = APP_ROUTES.careerReplays;
  });

  root.querySelector("#replay-play")?.addEventListener("click", () => player.play());
  root.querySelector("#replay-pause")?.addEventListener("click", () => player.pause());
  root.querySelector("#replay-step")?.addEventListener("click", () => player.stepForward());
  root.querySelector("#replay-reset")?.addEventListener("click", () => player.seekToStart());
  root.querySelector("#replay-speed")?.addEventListener("change", (e) => {
    const v = Number((e.target as HTMLSelectElement).value) as 0.5 | 1 | 2;
    player.setSpeed(v);
  });
}
