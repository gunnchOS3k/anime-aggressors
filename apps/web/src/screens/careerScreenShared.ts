import { navigateHome, navigateTo } from "../router.ts";
import { APP_ROUTES } from "../routes.ts";

export const PRIVACY_NOTE =
  "Career, saves, and replays are stored locally in this browser. Clearing site data may delete them.";

export function mountScreenShell(
  root: HTMLElement,
  opts: { title: string; subtitle?: string; backRoute?: string },
  contentHtml: string,
): void {
  root.innerHTML = `
    <div class="screen-shell career-screen">
      <header class="screen-header">
        <button type="button" class="btn-tertiary" id="screen-back">← Back</button>
        <div>
          <h1>${opts.title}</h1>
          ${opts.subtitle ? `<p class="screen-subtitle">${opts.subtitle}</p>` : ""}
        </div>
      </header>
      <p class="privacy-note">${PRIVACY_NOTE}</p>
      <div class="screen-content">${contentHtml}</div>
    </div>
  `;

  root.querySelector("#screen-back")?.addEventListener("click", () => {
    if (opts.backRoute) {
      window.location.hash = opts.backRoute;
    } else {
      navigateHome();
    }
  });
}

export function formatPlaytime(frames: number): string {
  const seconds = Math.floor(frames / 60);
  const mins = Math.floor(seconds / 60);
  const hrs = Math.floor(mins / 60);
  if (hrs > 0) return `${hrs}h ${mins % 60}m`;
  if (mins > 0) return `${mins}m ${seconds % 60}s`;
  return `${seconds}s`;
}

export function careerNav(): string {
  return `
    <nav class="career-nav">
      <a href="${APP_ROUTES.career}">Overview</a>
      <a href="${APP_ROUTES.careerFighters}">Fighter Stats</a>
      <a href="${APP_ROUTES.careerHistory}">Match History</a>
      <a href="${APP_ROUTES.careerReplays}">Replay Vault</a>
      <a href="${APP_ROUTES.careerSaves}">Saved Games</a>
      <a href="${APP_ROUTES.careerMilestones}">Milestones</a>
    </nav>
  `;
}

export function navigateCareerSub(route: string): void {
  window.location.hash = route;
}
