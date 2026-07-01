import { getProfileForSlot } from "../storage/inputProfileStorage.js";
import { APP_ROUTES, navigateToHash } from "../routes.js";
import {
  applySetupToMatchSession,
  isMatchSetupReady,
  loadMatchSetup,
  saveMatchSetup,
} from "../match/matchSetupSession.js";
import { renderSetupFlowShell } from "../ui/setup/SetupFlowShell.ts";
import {
  renderPlayerLoadoutCard,
  renderRulesStageSummary,
  renderVersusConfirmPanel,
} from "../ui/setup/VersusConfirmPanel.ts";
import { ARENA_CLASSES } from "../ui/theme/arenaClasses.ts";

export function mountMatchSetupControlsScreen(root: HTMLElement): void {
  const setup = loadMatchSetup();
  const p1 = setup.fighters.find((f) => f.playerId === 0)?.fighter;
  const p2 = setup.fighters.find((f) => f.playerId === 1)?.fighter;
  const p2Slot = setup.fighters.find((f) => f.playerId === 1);
  const p1Profile = getProfileForSlot(1);
  const p2Profile = getProfileForSlot(2);
  const ruleset = setup.ruleset;
  const cpuLevel = p2Slot?.cpuLevel ?? 1;
  const p2IsCpu = p2Slot?.isBot ?? false;

  const versusBody = renderVersusConfirmPanel(
    renderPlayerLoadoutCard("Player 1", p1 ?? null, p1Profile.name, true),
    renderPlayerLoadoutCard(p2IsCpu ? `CPU Lv${cpuLevel}` : "Player 2", p2 ?? null, p2Profile.name, true),
    renderRulesStageSummary(ruleset?.name ?? "Stock", setup.stageName ?? setup.stageId ?? "—"),
  );

  root.innerHTML = renderSetupFlowShell({
    step: "controls",
    title: "Ready to Fight",
    subtitle: "Confirm loadouts, CPU level, and test inputs before battle.",
    summary: `${ruleset?.name ?? "Stock"} · ${setup.stageName ?? setup.stageId ?? "Stage"}`,
    body: `
      ${versusBody}
      <div class="setup-cpu-panel setup-hero-panel">
        <strong>Player 2 mode</strong>
        <label><input type="radio" name="p2-mode" value="human" ${!p2IsCpu ? "checked" : ""}/> Local Player</label>
        <label><input type="radio" name="p2-mode" value="cpu" ${p2IsCpu ? "checked" : ""}/> CPU</label>
        <label>CPU level
          <select id="msc-cpu-level">
            <option value="1" ${cpuLevel === 1 ? "selected" : ""}>Level 1</option>
            <option value="2" ${cpuLevel === 2 ? "selected" : ""}>Level 2</option>
            <option value="3" ${cpuLevel === 3 ? "selected" : ""}>Level 3</option>
          </select>
        </label>
      </div>
      <div class="input-preview setup-hero-panel" id="ms-input-preview">
        <strong>Press any button to test inputs</strong>
        <div id="ms-input-log">Waiting for input…</div>
        <p class="setup-input-hint">P1: ${p1Profile.name} · P2: ${p2Profile.name}</p>
      </div>
    `,
    footer: {
      backId: "msc-back",
      backLabel: "Back to Character Select",
      continueId: "msc-start",
      continueLabel: "Start Battle",
      extraHtml: `<button type="button" id="msc-remap" class="${ARENA_CLASSES.secondaryBtn}">Remap Controls</button>`,
    },
  });

  const logEl = root.querySelector("#ms-input-log");
  const onKey = (e: KeyboardEvent) => {
    if (logEl) logEl.textContent = `Keyboard: ${e.code}`;
  };
  const onPad = () => {
    const pads = navigator.getGamepads?.() ?? [];
    const active = pads.find((p) => p && p.buttons.some((b) => b.pressed));
    if (active && logEl) logEl.textContent = `Gamepad: ${active.id.slice(0, 24)}`;
  };
  window.addEventListener("keydown", onKey);
  const padInterval = window.setInterval(onPad, 200);

  root.querySelector("#msc-remap")?.addEventListener("click", () => navigateToHash(APP_ROUTES.controlsRemap));
  root.querySelector("#msc-back")?.addEventListener("click", () => {
    window.removeEventListener("keydown", onKey);
    window.clearInterval(padInterval);
    navigateToHash(APP_ROUTES.stageSelect);
  });
  root.querySelector("#msc-start")?.addEventListener("click", () => {
    window.removeEventListener("keydown", onKey);
    window.clearInterval(padInterval);
    const cpuMode = (root.querySelector('input[name="p2-mode"]:checked') as HTMLInputElement)?.value === "cpu";
    const level = Number((root.querySelector("#msc-cpu-level") as HTMLSelectElement)?.value ?? 1) as 1 | 2 | 3;
    const next = {
      ...setup,
      fighters: setup.fighters.map((f) =>
        f.playerId === 1 ? { ...f, isBot: cpuMode, cpuLevel: level } : f,
      ),
    };
    saveMatchSetup(next);
    if (!isMatchSetupReady(next)) return;
    applySetupToMatchSession(next);
    navigateToHash(APP_ROUTES.battle);
  });
}
