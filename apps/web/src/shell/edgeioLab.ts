import { DEFAULT_EDGEIO_CONFIG, applyEdgeIOGesture } from "../input/edgeioMapper.js";
import { emptyInputFrame } from "../input/inputFrame.js";

export function mountEdgeIOLab(root: HTMLElement): void {
  root.innerHTML = `
    <div class="shell-panel">
      <button id="shell-back" type="button">← Home</button>
      <h2>Edge-IO Lab</h2>
      <p>Map wearable gestures into the shared <code>InputFrame</code> model. Hardware is optional — use buttons to simulate gestures.</p>
      <div class="edgeio-buttons">
        ${["swipeL", "swipeR", "swipeU", "swipeD", "thrust", "tap", "doubleTap", "block", "shake"]
          .map((g) => `<button type="button" data-gesture="${g}">${g}</button>`)
          .join("")}
      </div>
      <pre id="edgeio-output" class="shell-pre"></pre>
    </div>
  `;

  const out = root.querySelector("#edgeio-output") as HTMLPreElement;
  let gesture: string | undefined;

  root.querySelector("#shell-back")?.addEventListener("click", () => {
    window.dispatchEvent(new CustomEvent("aa:navigate-home"));
  });

  root.querySelector(".edgeio-buttons")?.addEventListener("click", (e) => {
    const btn = (e.target as HTMLElement).closest("button");
    if (!btn?.dataset.gesture) return;
    gesture = btn.dataset.gesture;
    render();
  });

  const render = () => {
    let frame = emptyInputFrame(0, 0);
    if (gesture) {
      frame = applyEdgeIOGesture(frame, gesture as never, DEFAULT_EDGEIO_CONFIG);
    }
    out.textContent = [
      `config: ${JSON.stringify(DEFAULT_EDGEIO_CONFIG)}`,
      `simulated gesture: ${gesture ?? "(none)"}`,
      `mapped input: ${JSON.stringify(frame, null, 2)}`,
      "",
      "See packages/edgeio and docs/EDGE_IO_PROTOCOL.md for binary protocol.",
    ].join("\n");
  };
  render();
}
