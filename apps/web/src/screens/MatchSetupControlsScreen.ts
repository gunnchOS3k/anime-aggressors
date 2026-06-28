import { getProfileForSlot } from "../storage/inputProfileStorage.js";
import { APP_ROUTES, navigateToHash } from "../routes.js";
import {
  applySetupToMatchSession,
  isMatchSetupReady,
  loadMatchSetup,
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
  const p1Profile = getProfileForSlot(1);
  const p2Profile = getProfileForSlot(2);
  const ruleset = setup.ruleset;

  const versusBody = renderVersusConfirmPanel(
    renderPlayerLoadoutCard("Player 1", p1 ?? null, p1Profile.name, true),
    renderPlayerLoadoutCard("Player 2", p2 ?? null, p2Profile.name, true),
    renderRulesStageSummary(ruleset?.name ?? "—", setup.stageName ?? setup.stageId ?? "—"),
  );

  root.innerHTML = renderSetupFlowShell({
    step: "controls",
    title: "Ready to Fight",
    subtitle: "Confirm loadouts and test inputs before battle.",
    summary: `${ruleset?.name ?? "Rules"} · ${setup.stageName ?? setup.stageId ?? "Stage"}`,
    body: `
      ${versusBody}
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
    navigateToHash(APP_ROUTES.matchSetupFighters);
  });
  root.querySelector("#msc-start")?.addEventListener("click", () => {
    window.removeEventListener("keydown", onKey);
    window.clearInterval(padInterval);
    if (!isMatchSetupReady(setup)) return;
    applySetupToMatchSession(setup);
    navigateToHash(APP_ROUTES.battle);
  });
}
