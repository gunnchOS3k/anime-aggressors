import type { GameAction } from "../input/actions.js";
import { ACTION_LABELS, GAME_ACTIONS } from "../input/actions.js";
import { formatBindingLabel } from "../input/inputBindings.js";
import type { InputProfile } from "../input/inputProfiles.js";
import {
  assignProfileToSlot,
  deleteInputProfile,
  duplicateInputProfile,
  ensureDefaultProfilesSaved,
  getProfileForSlot,
  listInputProfiles,
  resetInputProfilesToDefaults,
  saveInputProfile,
} from "../storage/inputProfileStorage.js";
import { navigateTo } from "../router.js";
import { resolveProfileActions } from "../input/profileInput.js";
import { getPressedKeyCodes } from "../input/keyboard.js";
import { getConnectedGamepads, gamepadToState } from "../input/gamepad.js";

export function mountControlsScreen(root: HTMLElement): void {
  ensureDefaultProfilesSaved();
  let activeSlot: 1 | 2 | 3 | 4 = 1;
  let editing = getProfileForSlot(activeSlot);

  const render = () => {
    editing = getProfileForSlot(activeSlot);
    const profiles = listInputProfiles();
    const blocked = activeSlot > 2;

    root.innerHTML = `
      <div class="screen controls-screen">
        <div class="screen-toolbar">
          <button type="button" id="ctl-back" class="btn-secondary">← Home</button>
          <h2>Controls</h2>
        </div>
        <p class="hint">Assign input profiles per player. Remap keyboard, gamepad, or Edge-IO.</p>

        <div class="slot-row">
          ${([1, 2, 3, 4] as const)
            .map(
              (s) =>
                `<button type="button" class="slot-btn ${activeSlot === s ? "selected" : ""}" data-slot="${s}">P${s}${s > 2 ? " 🔒" : ""}</button>`,
            )
            .join("")}
        </div>

        ${blocked ? `<p class="ship-blocked">P3/P4 SHIP BLOCKED: waiting on 4-player spawn/camera/HUD pass</p>` : ""}

        <div class="controls-detail">
          <p><strong>Player Slot:</strong> P${activeSlot}</p>
          <p><strong>Active Device:</strong> ${editing.deviceType}</p>
          <p><strong>Active Profile:</strong> ${editing.name}</p>
          <label>Profile
            <select id="ctl-profile-select">
              ${profiles.map((p) => `<option value="${p.id}" ${p.id === editing.id ? "selected" : ""}>${p.name}</option>`).join("")}
            </select>
          </label>
        </div>

        <div class="binding-list">
          <h3>Current Bindings</h3>
          ${GAME_ACTIONS.filter((a) => !["pause", "taunt", "debugToggle"].includes(a))
            .map((action) => {
              const binding = editing.bindings[action];
              return `<button type="button" class="binding-row" data-action="${action}">
                <span>${ACTION_LABELS[action]}</span>
                <span>${binding ? formatBindingLabel(binding) : "—"}</span>
              </button>`;
            })
            .join("")}
        </div>

        <pre id="ctl-test-output" class="shell-pre">Test inputs below…</pre>

        <div class="create-actions">
          <button type="button" id="ctl-remap" class="btn-secondary" ${blocked ? "disabled" : ""}>Remap…</button>
          <button type="button" id="ctl-reset" class="btn-tertiary">Reset Profile</button>
          <button type="button" id="ctl-save" class="btn-secondary">Save Profile</button>
          <button type="button" id="ctl-dup" class="btn-tertiary">Duplicate Profile</button>
          <button type="button" id="ctl-del" class="btn-tertiary">Delete Profile</button>
        </div>
      </div>
    `;

    bind();
    startTestLoop();
  };

  let testRaf = 0;
  const startTestLoop = () => {
    cancelAnimationFrame(testRaf);
    const out = root.querySelector("#ctl-test-output") as HTMLPreElement | null;
    if (!out) return;
    const tick = () => {
      const keyboard = getPressedKeyCodes();
      const pads = getConnectedGamepads();
      const pad = pads[activeSlot - 1] ? gamepadToState(pads[activeSlot - 1]!) : null;
      const actions = resolveProfileActions(editing, keyboard, pad);
      const pressed = Object.entries(actions)
        .filter(([, v]) => v)
        .map(([a]) => ACTION_LABELS[a as GameAction])
        .join(", ");
      out.textContent = `Test Inputs: ${pressed || "(none)"}\nDeadzone: ${editing.deadzone} · Stick: ${editing.stickSensitivity}`;
      testRaf = requestAnimationFrame(tick);
    };
    tick();
  };

  const bind = () => {
    root.querySelector("#ctl-back")?.addEventListener("click", () => {
      cancelAnimationFrame(testRaf);
      navigateTo("home");
    });
    root.querySelectorAll(".slot-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        activeSlot = Number((btn as HTMLButtonElement).dataset.slot) as 1 | 2 | 3 | 4;
        render();
      });
    });
    root.querySelector("#ctl-profile-select")?.addEventListener("change", (e) => {
      const id = (e.target as HTMLSelectElement).value;
      assignProfileToSlot(activeSlot, id);
      render();
    });
    root.querySelectorAll(".binding-row").forEach((btn) => {
      btn.addEventListener("click", () => {
        if (activeSlot > 2) return;
        const action = (btn as HTMLButtonElement).dataset.action as GameAction;
        navigateTo("controls-remap", { action, slot: activeSlot });
      });
    });
    root.querySelector("#ctl-remap")?.addEventListener("click", () => {
      navigateTo("controls-remap", { action: "attack", slot: activeSlot });
    });
    root.querySelector("#ctl-reset")?.addEventListener("click", () => {
      import("../input/remapInput.js").then(({ resetProfileBindings }) => {
        editing = resetProfileBindings(editing);
        saveInputProfile(editing);
        assignProfileToSlot(activeSlot, editing.id);
        render();
      });
    });
    root.querySelector("#ctl-save")?.addEventListener("click", () => {
      saveInputProfile(editing);
      assignProfileToSlot(activeSlot, editing.id);
      alert("Profile saved.");
    });
    root.querySelector("#ctl-dup")?.addEventListener("click", () => {
      duplicateInputProfile(editing.id);
      render();
    });
    root.querySelector("#ctl-del")?.addEventListener("click", () => {
      deleteInputProfile(editing.id);
      resetInputProfilesToDefaults();
      ensureDefaultProfilesSaved();
      render();
    });
  };

  render();
}
