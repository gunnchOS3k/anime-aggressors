import { navigateHome } from "../router.js";
import { APP_VERSION_LABEL } from "../version.ts";
import { resetDemoOnboarding } from "../demo/demoOnboarding.ts";
import { ARENA_CLASSES } from "../ui/theme/arenaClasses.ts";

export function mountAboutScreen(root: HTMLElement): void {
  root.innerHTML = `
    <div class="screen about-screen" data-testid="about-screen">
      <div class="screen-toolbar">
        <button type="button" id="about-back" class="btn-secondary">← Home</button>
        <h2>About &amp; Credits</h2>
      </div>
      <div class="about-body setup-hero-panel">
        <h3>Anime Aggressors</h3>
        <p class="about-tagline">2.5D anime platform fighter — web demo vertical slice.</p>
        <p><strong>Build:</strong> ${APP_VERSION_LABEL}</p>
        <p><strong>Roster:</strong> 7 playable fighters (4 production-validated, 3 preview/balance-pending).</p>
        <p><strong>Stages:</strong> Training Grid, Skyline Arena, Neon Rooftops.</p>
        <p><strong>Modes:</strong> Quick Match, custom setup, training, local 2P keyboard/gamepad.</p>
        <p class="about-note">This public demo runs on TypeScript + Three.js. Engine migration is documented separately and is not part of this build.</p>
        <h4>Credits</h4>
        <ul>
          <li>Simulation: <code>@anime-aggressors/game-core</code></li>
          <li>Rendering: Three.js procedural fighters &amp; stages</li>
          <li>Audio: procedural Web Audio placeholders</li>
        </ul>
        <div class="about-actions">
          <button type="button" id="about-show-help" class="${ARENA_CLASSES.secondaryBtn}">Show first-match help again</button>
        </div>
        <p id="about-help-status" class="hint" hidden>First-match help will appear on your next battle.</p>
      </div>
    </div>
  `;

  root.querySelector("#about-back")?.addEventListener("click", () => navigateHome());
  root.querySelector("#about-show-help")?.addEventListener("click", () => {
    resetDemoOnboarding();
    const status = root.querySelector("#about-help-status") as HTMLElement | null;
    if (status) status.hidden = false;
  });
}
