import {
  fetchGodotBuildManifest,
  probeGodotExport,
  versionedGodotIndexPath,
} from "../godot/godotExportStatus.ts";

export function mountGodotRuntimeScreen(root: HTMLElement): void {
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
        <p class="godot-runtime-note">
          Legacy Web Prototype remains on the main menu for the TypeScript/Three.js build.
        </p>
        <div class="godot-runtime-actions">
          <a id="godot-open-tab" class="primary-game-cta" href="#" target="_blank" rel="noopener">Open Godot Build</a>
          <button type="button" id="godot-reload-frame" class="secondary-game-button">Reload Embed</button>
        </div>
        <p id="godot-build-id" class="godot-runtime-note hidden"></p>
      </div>
      <div id="godot-export-error" class="godot-export-error setup-hero-panel hidden" role="alert"></div>
      <div class="godot-runtime-frame-wrap stage-preview-canvas-wrap">
        <iframe
          id="godot-runtime-frame"
          class="godot-runtime-frame hidden"
          title="Anime Aggressors Godot Runtime"
          allow="fullscreen"
        ></iframe>
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
  const errorPanel = root.querySelector("#godot-export-error");
  const openTab = root.querySelector<HTMLAnchorElement>("#godot-open-tab");
  const reloadBtn = root.querySelector("#godot-reload-frame");
  const buildIdLabel = root.querySelector("#godot-build-id");

  function showError(message: string) {
    if (errorPanel) {
      errorPanel.classList.remove("hidden");
      errorPanel.innerHTML = `<h3>Godot export unavailable</h3><p>${message}</p>`;
    }
    frame?.classList.add("hidden");
    openTab?.classList.add("disabled");
  }

  function showReady(embedUrl: string, buildId: string) {
    errorPanel?.classList.add("hidden");
    if (frame) {
      frame.src = embedUrl;
      frame.classList.remove("hidden");
    }
    if (openTab) {
      openTab.href = embedUrl;
      openTab.classList.remove("disabled");
    }
    if (buildIdLabel) {
      buildIdLabel.textContent = `Godot build ${buildId}`;
      buildIdLabel.classList.remove("hidden");
    }
  }

  async function loadEmbed() {
    const manifest = await fetchGodotBuildManifest();
    if (!manifest) {
      showError(
        "Godot build manifest missing. The Pages artifact is incomplete. Run <code>npm run godot:export:web</code> and redeploy.",
      );
      return;
    }
    const status = await probeGodotExport();
    if (status === "placeholder") {
      showError(
        "Placeholder export is deployed. Real Godot export was not built. Run <code>npm run godot:export:web</code> with Godot 4.3+.",
      );
      return;
    }
    if (status === "missing" || status === "manifest-missing") {
      showError(
        "Godot Web export is missing. Run <code>npm run godot:export:web</code> with Godot 4.3+ installed.",
      );
      return;
    }
    showReady(versionedGodotIndexPath(manifest), manifest.buildId);
  }

  reloadBtn?.addEventListener("click", () => {
    void loadEmbed();
  });

  void loadEmbed();
}
