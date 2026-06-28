import { APP_ROUTES } from "../routes.ts";
import { APP_VERSION_LABEL } from "../version.ts";

export function renderMainMenuFooter(): string {
  return `<footer class="menu-footer" aria-label="Build info">
    <span class="menu-footer__build">Build: ${APP_VERSION_LABEL}</span>
    <span class="menu-footer__route">Route: ${APP_ROUTES.home}</span>
  </footer>`;
}
