import { installHashRouter, navigateHome, bindRouteButtons } from "./router.js";
import type { AppRouteMode } from "./routes.js";
import { APP_VERSION_LABEL, APP_EXPECTED_MODES } from "./version.js";
import "./styles.css";

const home = document.getElementById("home-view");
const appRoot = document.getElementById("app-root");

function showHome(): void {
  if (appRoot) {
    appRoot.innerHTML = "";
    appRoot.classList.add("hidden");
  }
  home?.classList.remove("hidden");
}

async function navigate(mode: AppRouteMode): Promise<void> {
  if (mode === "home") {
    showHome();
    return;
  }

  home?.classList.add("hidden");
  appRoot?.classList.remove("hidden");
  if (appRoot) appRoot.innerHTML = "";

  try {
    if (mode === "match") {
      const { launchMatch } = await import("./game/App.js");
      launchMatch(appRoot!);
    } else if (mode === "training") {
      const { launchTrainingMode } = await import("./game/App.js");
      launchTrainingMode(appRoot!);
    } else if (mode === "controller") {
      const { mountControllerTest } = await import("./shell/controllerTest.js");
      mountControllerTest(appRoot!);
    } else if (mode === "rollback") {
      const { mountRollbackDebug } = await import("./shell/rollbackDebug.js");
      mountRollbackDebug(appRoot!);
    } else if (mode === "edgeio") {
      const { mountEdgeIOLab } = await import("./shell/edgeioLab.js");
      mountEdgeIOLab(appRoot!);
    } else if (mode === "prototype") {
      const { mountPrototypeLab } = await import("./shell/prototypeLab.js");
      mountPrototypeLab(appRoot!);
    } else if (mode === "impact-dummy-derby") {
      const { mountImpactDummyDerby } = await import("./modes/impactDummyDerbyView.js");
      mountImpactDummyDerby(appRoot!);
    }
  } catch (error) {
    console.error(error);
    if (appRoot) {
      appRoot.innerHTML = '<p style="color:#ff6b6b">Failed to load module.</p>';
    }
  }
}

window.addEventListener("aa:navigate-home", () => navigateHome());

bindRouteButtons();
installHashRouter(navigate);

const buildFooter = document.getElementById("build-footer");
if (buildFooter) {
  buildFooter.textContent = `Build: ${APP_VERSION_LABEL}`;
  buildFooter.title = APP_EXPECTED_MODES.join(" · ");
}

export { launchMatch, launchTrainingMode } from "./game/App.js";
export { bootstrapMiniGames } from "./minigames/bootstrap.js";
export { mountPrototypeLab } from "./shell/prototypeLab.js";
export { mountImpactDummyDerby } from "./modes/impactDummyDerbyView.js";
