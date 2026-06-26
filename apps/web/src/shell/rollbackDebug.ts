import {
  createInitialGameState,
  replay,
  hashState,
  type GameConfig,
  type InputFrame,
} from "@anime-aggressors/game-core";
import { RollbackSession } from "@anime-aggressors/rollback";

export function mountRollbackDebug(root: HTMLElement): void {
  root.innerHTML = `
    <div class="shell-panel">
      <button id="shell-back" type="button">← Home</button>
      <h2>Rollback Debug</h2>
      <p>Runs a deterministic replay with injected late inputs to exercise rollback snapshots.</p>
      <button id="run-rollback" type="button" class="btn-primary">Run rollback scenario</button>
      <pre id="rollback-output" class="shell-pre"></pre>
    </div>
  `;

  const out = root.querySelector("#rollback-output") as HTMLPreElement;
  root.querySelector("#shell-back")?.addEventListener("click", () => {
    window.dispatchEvent(new CustomEvent("aa:navigate-home"));
  });

  root.querySelector("#run-rollback")?.addEventListener("click", () => {
    const config: GameConfig = {
      playerCount: 2,
      stocks: 3,
      matchDurationFrames: 180 * 60,
      stageId: "skyline-arena",
      characterIds: ["ember", "tide"],
      seed: 42,
    };

    let state = createInitialGameState(config);
    const inputLog: InputFrame[][] = [];
    const session = new RollbackSession(state, {
      snapshotInterval: 1,
      maxRollbackFrames: 120,
      playerCount: 2,
    });

    let rollbacks = 0;
    for (let f = 0; f < 120; f++) {
      const frameInputs: InputFrame[] = [
        {
          frame: f,
          playerId: 0,
          left: f % 20 < 10,
          right: false,
          up: false,
          down: false,
          jump: f === 30,
          attack: f === 45,
          special: false,
          shield: false,
          dodge: false,
          grab: false,
        },
        {
          frame: f,
          playerId: 1,
          left: false,
          right: f % 15 < 8,
          up: false,
          down: false,
          jump: false,
          attack: f === 50,
          special: false,
          shield: false,
          dodge: false,
          grab: false,
        },
      ];
      inputLog.push(frameInputs);
      const before = session.getRollbackCount();
      state = session.advanceFrame(frameInputs, [true, true]);
      if (session.getRollbackCount() > before) rollbacks = session.getRollbackCount();
    }

    const initial = createInitialGameState(config);
    const replayResult = replay(initial, inputLog);
    const match = hashState(state) === replayResult.finalHash;

    out.textContent = [
      `frames simulated: 120`,
      `rollback count: ${rollbacks}`,
      `final hash (session): ${hashState(state)}`,
      `final hash (replay):  ${replayResult.finalHash}`,
      `determinism match: ${match ? "PASS" : "FAIL"}`,
      `P1 damage: ${state.players[0].damage}%`,
      `P2 damage: ${state.players[1].damage}%`,
    ].join("\n");
  });
}
