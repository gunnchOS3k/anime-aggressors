import type { GameAction } from "../input/actions.js";
import { ACTION_LABELS } from "../input/actions.js";
import {
  applyBinding,
  captureGamepadAxis,
  captureGamepadButton,
  captureKeyboardBinding,
  resetActionBinding,
  resetProfileBindings,
} from "../input/remapInput.js";
import { getProfileForSlot, saveInputProfile } from "../storage/inputProfileStorage.js";
import { navigateTo } from "../router.js";
import { gamepadToState, getConnectedGamepads } from "../input/gamepad.js";

export type RemapRouteParams = {
  action?: GameAction;
  slot?: 1 | 2 | 3 | 4;
};

export function mountInputRemapScreen(
  root: HTMLElement,
  params: RemapRouteParams = {},
): void {
  const slot = params.slot ?? 1;
  const action = params.action ?? "attack";
  let profile = getProfileForSlot(slot);
  let listening = true;
  let conflictMessage = "";

  const render = () => {
    root.innerHTML = `
      <div class="screen remap-screen">
        <div class="screen-toolbar">
          <button type="button" id="rm-back" class="btn-secondary">← Controls</button>
          <h2>Remap: ${ACTION_LABELS[action]}</h2>
        </div>
        <p class="hint">${listening ? `Press a key or controller button for ${ACTION_LABELS[action]}` : "Binding updated."}</p>
        ${conflictMessage ? `<p class="conflict">${conflictMessage}</p>` : ""}
        <div class="create-actions">
          <button type="button" id="rm-save" class="btn-primary">Save</button>
          <button type="button" id="rm-cancel" class="btn-secondary">Cancel</button>
          <button type="button" id="rm-reset-action" class="btn-tertiary">Reset Action</button>
          <button type="button" id="rm-reset-profile" class="btn-tertiary">Reset Profile</button>
        </div>
      </div>
    `;

    root.querySelector("#rm-back")?.addEventListener("click", cleanupAndBack);
    root.querySelector("#rm-cancel")?.addEventListener("click", cleanupAndBack);
    root.querySelector("#rm-save")?.addEventListener("click", () => {
      saveInputProfile(profile);
      cleanupAndBack();
    });
    root.querySelector("#rm-reset-action")?.addEventListener("click", () => {
      profile = resetActionBinding(profile, action);
      listening = false;
      render();
    });
    root.querySelector("#rm-reset-profile")?.addEventListener("click", () => {
      profile = resetProfileBindings(profile);
      listening = false;
      render();
    });
  };

  const cleanupAndBack = () => {
    window.removeEventListener("keydown", onKeyDown);
    navigateTo("controls");
  };

  const onKeyDown = (e: KeyboardEvent) => {
    if (!listening) return;
    e.preventDefault();
    const binding = captureKeyboardBinding(e.code);
    const result = applyBinding(profile, action, binding, false);
    if (result.conflict) {
      conflictMessage = `${ACTION_LABELS[result.conflict.action]} already uses this input.`;
      if (window.confirm(`Replace ${ACTION_LABELS[result.conflict.action]}?`)) {
        profile = applyBinding(profile, action, binding, true).profile;
        listening = false;
        conflictMessage = "";
        render();
      }
    } else {
      profile = result.profile;
      listening = false;
      render();
    }
  };

  const pollGamepad = () => {
    if (!listening) return;
    const pads = getConnectedGamepads();
    const pad = pads[slot - 1];
    if (pad) {
      const state = gamepadToState(pad);
      for (let i = 0; i < state.buttons.length; i++) {
        if (state.buttons[i]) {
          const result = applyBinding(profile, action, captureGamepadButton(i), false);
          profile = result.conflict
            ? applyBinding(profile, action, captureGamepadButton(i), true).profile
            : result.profile;
          listening = false;
          render();
          return;
        }
      }
      for (let i = 0; i < state.axes.length; i++) {
        const v = state.axes[i];
        if (Math.abs(v) > 0.5) {
          profile = applyBinding(
            profile,
            action,
            captureGamepadAxis(i, v < 0 ? "negative" : "positive"),
            true,
          ).profile;
          listening = false;
          render();
          return;
        }
      }
    }
    requestAnimationFrame(pollGamepad);
  };

  render();
  window.addEventListener("keydown", onKeyDown);
  requestAnimationFrame(pollGamepad);
}
