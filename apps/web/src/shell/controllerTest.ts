import { pollAllInputs } from "../input/deviceAssignment.js";
import { getConnectedGamepads, gamepadToState } from "../input/gamepad.js";
import { getProfileForSlot } from "../storage/inputProfileStorage.js";
import { resolveProfileActions } from "../input/profileInput.js";
import { ACTION_LABELS } from "../input/actions.js";
import { getPressedKeyCodes } from "../input/keyboard.js";
import { actionFromRawInput } from "../input/profileInput.js";
import { listInputProfiles } from "../storage/inputProfileStorage.js";

export function mountControllerTest(root: HTMLElement): void {
  let testRemap = false;

  const renderShell = () => {
    root.innerHTML = `
      <div class="shell-panel">
        <button id="shell-back" type="button">← Home</button>
        <h2>Controller Test</h2>
        <p>Keyboard, gamepad, and remapped action preview.</p>
        <label><input type="checkbox" id="ct-remap-mode" ${testRemap ? "checked" : ""}/> Test Remap mode</label>
        <pre id="controller-output" class="shell-pre"></pre>
      </div>
    `;
    root.querySelector("#shell-back")?.addEventListener("click", () => {
      cancelAnimationFrame(raf);
      import("../router.js").then(({ navigateHome }) => navigateHome());
    });
    root.querySelector("#ct-remap-mode")?.addEventListener("change", (e) => {
      testRemap = (e.target as HTMLInputElement).checked;
    });
  };

  renderShell();
  const out = () => root.querySelector("#controller-output") as HTMLPreElement;

  let frame = 0;
  let raf = 0;
  const tick = () => {
    const inputs = pollAllInputs(frame);
    const pads = getConnectedGamepads();
    const lines: string[] = [`frame ${frame}`, ""];

    pads.forEach((pad, i) => {
      if (!pad) return;
      const state = gamepadToState(pad);
      const profile = getProfileForSlot((i + 1) as 1 | 2);
      lines.push(`Gamepad ${i}: ${pad.id}`);
      lines.push(`  Profile: ${profile.name} · deadzone ${profile.deadzone} · sens ${profile.stickSensitivity}`);
      lines.push(`  Buttons: ${state.buttons.map((b, idx) => (b ? idx : null)).filter((v) => v !== null).join(", ") || "none"}`);
      lines.push(`  Axes: ${state.axes.map((a) => a.toFixed(2)).join(", ")}`);
      const actions = resolveProfileActions(profile, getPressedKeyCodes(), state);
      const active = Object.entries(actions)
        .filter(([, v]) => v)
        .map(([a]) => ACTION_LABELS[a as keyof typeof ACTION_LABELS])
        .join(", ");
      lines.push(`  Actions: ${active || "(idle)"}`);
      lines.push("");
    });

    lines.push("Match input frames:");
    for (const i of inputs) {
      const flags = [
        i.left && "←",
        i.right && "→",
        i.up && "↑",
        i.down && "↓",
        i.jump && "J",
        i.attack && "A",
        i.special && "S",
        i.shield && "Sh",
        i.dodge && "D",
        i.grab && "G",
      ].filter(Boolean);
      lines.push(`P${i.playerId + 1}: ${flags.join(" ") || "(idle)"}`);
    }

    if (testRemap) {
      const hit = actionFromRawInput(listInputProfiles(), getPressedKeyCodes(), pads[0] ? gamepadToState(pads[0]) : null);
      lines.push("");
      lines.push(hit ? `Remap hit: ${hit.action} (${hit.profile.name})` : "Remap: press any bound input");
    }

    out().textContent = lines.join("\n");
    frame += 1;
    raf = requestAnimationFrame(tick);
  };
  tick();
}
