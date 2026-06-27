import { getProfileForSlot } from "../storage/inputProfileStorage.js";
import { APP_ROUTES, navigateToHash } from "../routes.js";
import {
  applySetupToMatchSession,
  isMatchSetupReady,
  loadMatchSetup,
} from "../match/matchSetupSession.js";

export function mountMatchSetupControlsScreen(root: HTMLElement): void {
  const setup = loadMatchSetup();
  const p1 = setup.fighters.find((f) => f.playerId === 0)?.fighter;
  const p2 = setup.fighters.find((f) => f.playerId === 1)?.fighter;
  const p1Profile = getProfileForSlot(1);
  const p2Profile = getProfileForSlot(2);
  const ruleset = setup.ruleset;

  root.innerHTML = `
    <div class="screen match-setup-controls">
      <h2>Controls Check</h2>
      <p class="hint">Confirm setup and test inputs before battle.</p>
      <div class="check-grid">
        <div><strong>Rules</strong><br/>${ruleset?.name ?? "—"}</div>
        <div><strong>Stage</strong><br/>${setup.stageName ?? setup.stageId ?? "—"}</div>
        <div><strong>P1</strong><br/>${p1?.name ?? "—"}<br/><small>${p1Profile.name}</small></div>
        <div><strong>P2</strong><br/>${p2?.name ?? "—"}<br/><small>${p2Profile.name}</small></div>
      </div>
      <div class="input-preview" id="ms-input-preview">
        <strong>Press any button</strong>
        <div id="ms-input-log">Waiting for input…</div>
      </div>
      <div class="create-actions">
        <button type="button" id="msc-remap" class="btn-secondary">Remap Controls</button>
        <button type="button" id="msc-back" class="btn-secondary">Back to Character Select</button>
        <button type="button" id="msc-start" class="btn-primary">Start Battle</button>
      </div>
    </div>
  `;

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
