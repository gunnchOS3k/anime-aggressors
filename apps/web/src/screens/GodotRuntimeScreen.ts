export function mountGodotRuntimeScreen(root: HTMLElement): void {
  const base = import.meta.env.BASE_URL ?? "/";
  const godotUrl = `${base}godot/index.html`;
  const legacyNote =
    "The TypeScript/Three.js build remains available as Legacy Web Prototype from the main menu.";

  root.innerHTML = `
    <div class="godot-runtime-shell setup-shell">
      <div class="vs-toolbar">
        <button type="button" id="godot-back" class="secondary-game-button">← Home</button>
        <span class="vs-hint">Godot Combat Prototype</span>
      </div>
      <div class="setup-hero-panel godot-runtime-hero">
        <h2>Play Godot Combat Prototype</h2>
        <p>
          Anime Aggressors gameplay runs in <strong>Godot 4</strong> for responsive platform-fighter movement,
          limb animation, hitstop, knockback, and camera framing.
        </p>
        <p class="godot-runtime-note">${legacyNote}</p>
        <div class="godot-runtime-actions">
          <a id="godot-open-tab" class="primary-game-cta" href="${godotUrl}" target="_blank" rel="noopener">Open Godot Build</a>
          <button type="button" id="godot-reload-frame" class="secondary-game-button">Reload Embed</button>
        </div>
      </div>
      <div class="godot-runtime-frame-wrap stage-preview-canvas-wrap">
        <iframe
          id="godot-runtime-frame"
          class="godot-runtime-frame"
          title="Anime Aggressors Godot Runtime"
          src="${godotUrl}"
          allow="fullscreen"
        ></iframe>
        <p id="godot-frame-fallback" class="godot-frame-fallback hidden">
          Godot web export not found. Run <code>npm run godot:export:web</code> with Godot 4 CLI installed,
          or see <code>docs/GODOT_EXPORT_GUIDE.md</code>.
        </p>
      </div>
      <details class="godot-runtime-controls setup-hero-panel">
        <summary>Default Controls</summary>
        <ul>
          <li><strong>P1:</strong> Move A/D · Jump W/Space · Attack J · Special K · Shield L · Aura F</li>
          <li><strong>P2:</strong> Move ←/→ · Jump ↑/Numpad0 · Attack Numpad1 · Special Numpad2 · Shield Numpad3 · Aura /</li>
        </ul>
      </details>
    </div>
  `;

  root.querySelector("#godot-back")?.addEventListener("click", () => {
    window.dispatchEvent(new CustomEvent("aa:navigate-home"));
  });

  const frame = root.querySelector<HTMLIFrameElement>("#godot-runtime-frame");
  const fallback = root.querySelector("#godot-frame-fallback");
  const reloadBtn = root.querySelector("#godot-reload-frame");

  reloadBtn?.addEventListener("click", () => {
    if (frame) frame.src = godotUrl;
  });

  void fetch(godotUrl, { method: "HEAD" })
    .then((res) => {
      if (!res.ok && fallback && frame) {
        fallback.classList.remove("hidden");
        frame.classList.add("hidden");
      }
    })
    .catch(() => {
      if (fallback && frame) {
        fallback.classList.remove("hidden");
        frame.classList.add("hidden");
      }
    });
}
