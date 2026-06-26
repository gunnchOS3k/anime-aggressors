import { pollAllInputs } from "../input/deviceAssignment.js";

export function mountControllerTest(root: HTMLElement): void {
  root.innerHTML = `
    <div class="shell-panel">
      <button id="shell-back" type="button">← Home</button>
      <h2>Controller Test</h2>
      <p>Keyboard, gamepad, and Edge-IO gesture mapping preview. Inputs are polled live — no match simulation.</p>
      <pre id="controller-output" class="shell-pre"></pre>
    </div>
  `;

  const out = root.querySelector("#controller-output") as HTMLPreElement;
  root.querySelector("#shell-back")?.addEventListener("click", () => {
    cancelAnimationFrame(raf);
    import("../router.js").then(({ navigateHome }) => navigateHome());
  });

  let frame = 0;
  let raf = 0;
  const tick = () => {
    const inputs = pollAllInputs(frame);
    const lines = inputs.map((i) => {
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
        i.wearableGesture && `W:${i.wearableGesture}`,
      ].filter(Boolean);
      return `P${i.playerId + 1}: ${flags.join(" ") || "(idle)"}`;
    });
    out.textContent = `frame ${frame}\n${lines.join("\n")}\n\nP1: Arrows + ZXCVB | P2: WASD + 12345`;
    frame += 1;
    raf = requestAnimationFrame(tick);
  };
  tick();
}
