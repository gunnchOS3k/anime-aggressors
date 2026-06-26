import {
  createInitialFlaglineState,
  simulateFlaglineFrame,
  getFlaglineRoom,
  type FlaglineClashState,
} from "@anime-aggressors/game-core";
import { pollPlayerInput } from "../input/deviceAssignment.js";
import { ThreeGameRenderer } from "../renderer-three/ThreeGameRenderer.js";
import { FlagCoreView } from "../renderer-three/FlagCoreView.js";
import { FlaglineStageView } from "../renderer-three/FlaglineStageView.js";
import { renderFlaglineHUD } from "../screens/FlaglineClashHUD.js";
import { mountFlaglineClashResultsScreen } from "../screens/FlaglineClashResultsScreen.js";
import { getPendingTeamSelect } from "../screens/TeamSelectScreen.js";
import { navigateHome, navigateTo } from "../router.js";
import { ReplayRecorder } from "../replay/ReplayRecorder.js";
import { StatEventTracker, processFlaglineEnd } from "../career/careerService.js";
import { DEFAULT_RULESET } from "@anime-aggressors/game-core";

export function mountFlaglineClash(root: HTMLElement): void {
  const pending = getPendingTeamSelect();
  const teamSlots = pending?.teamSlots;
  const config = pending?.config;

  root.innerHTML = `
    <div class="pf-root flagline-root">
      <div class="vs-toolbar">
        <button id="fl-back" type="button">← Home</button>
        <span class="vs-hint">Flagline Clash · P1 Solar · P2 Lunar · Bots fill empty slots</span>
      </div>
      <div class="pf-viewport-wrap">
        <div id="fl-viewport" class="pf-viewport"></div>
        <div id="fl-hud" class="pf-hud flagline-hud-host"></div>
      </div>
    </div>
  `;

  const viewport = root.querySelector("#fl-viewport") as HTMLElement;
  const hud = root.querySelector("#fl-hud") as HTMLElement;

  let state: FlaglineClashState = createInitialFlaglineState(42, config, teamSlots, 0);
  const initialGame = structuredClone(state.game);
  const recorder = new ReplayRecorder({
    gameVersion: "0.1.0",
    mode: "flaglineClash",
    ruleset: config ?? DEFAULT_RULESET,
    title: "Flagline Clash Replay",
  });
  recorder.start(state.game);
  const statTracker = new StatEventTracker("flaglineClash");
  statTracker.initFromState(state.game);
  statTracker.start(0);
  let careerProcessed = false;

  const renderer = new ThreeGameRenderer(viewport, { smoothCamera: true });
  renderer.mount();
  const flagCoreView = new FlagCoreView();
  const stageTheme = new FlaglineStageView();
  renderer.getScene().add(flagCoreView.group);
  renderer.getScene().add(stageTheme.group);

  let raf = 0;
  let simFrame = 0;
  const fixedDt = 1 / 60;
  let last = performance.now();
  let acc = 0;

  root.querySelector("#fl-back")?.addEventListener("click", () => {
    cancelAnimationFrame(raf);
    renderer.dispose();
    navigateHome();
  });

  const tick = (now: number) => {
    acc += Math.min((now - last) / 1000, 0.1);
    last = now;
    while (acc >= fixedDt) {
      if (state.flagline.phase !== "gameWon") {
        const humanInputs = [pollPlayerInput(simFrame, 0), pollPlayerInput(simFrame, 1)];
        state = simulateFlaglineFrame(state, humanInputs);
        recorder.recordFrame(simFrame, humanInputs);
        statTracker.trackFrame(state.game, humanInputs);
        simFrame += 1;
      }
      acc -= fixedDt;
    }

    if (state.flagline.phase === "gameWon") {
      cancelAnimationFrame(raf);
      renderer.dispose();
      if (!careerProcessed) {
        careerProcessed = true;
        for (const room of state.flagline.roomHistory) {
          if (room.winner) {
            statTracker.addEvent({
              type: "flaglineRoomWon",
              frame: room.frame,
              teamId: room.winner,
              roomIndex: room.roomIndex,
            });
          }
        }
        void processFlaglineEnd(initialGame, state, statTracker.getEvents(), recorder).then(
          (result) => {
            mountFlaglineClashResultsScreen(
              root,
              state,
              () => {
                state = createInitialFlaglineState(42, config, teamSlots, 0);
                mountFlaglineClash(root);
              },
              () => navigateHome(),
              result,
            );
          },
        );
      }
      return;
    }

    renderer.update(state.game, { showBlastZones: false });
    const room = getFlaglineRoom(state.flagline.currentRoomIndex);
    flagCoreView.update({
      x: room.flagCore.x,
      y: room.flagCore.y,
      width: room.flagCore.width,
      height: room.flagCore.height,
      solarCapture: state.flagline.capture.solar,
      lunarCapture: state.flagline.capture.lunar,
      captureToWin: state.config.captureToWin,
      contested: state.flagline.capture.contested,
    });
    stageTheme.setRoomTheme(state.flagline.currentRoomIndex);
    renderer.render();
    renderFlaglineHUD(hud, state);
    raf = requestAnimationFrame(tick);
  };

  raf = requestAnimationFrame(tick);
}
