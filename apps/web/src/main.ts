import { installHashRouter, navigateHome, bindRouteButtons, getRouteParams } from "./router.js";
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
    if (mode === "match-setup-rules") {
      const { mountMatchSetupRulesScreen } = await import("./screens/MatchSetupRulesScreen.js");
      mountMatchSetupRulesScreen(appRoot!);
    } else if (mode === "match-setup-stage") {
      const { mountMatchSetupStageScreen } = await import("./screens/MatchSetupStageScreen.js");
      mountMatchSetupStageScreen(appRoot!);
    } else if (mode === "match-setup-fighters") {
      const { mountMatchSetupFightersScreen } = await import("./screens/MatchSetupFightersScreen.js");
      mountMatchSetupFightersScreen(appRoot!);
    } else if (mode === "match-setup-controls") {
      const { mountMatchSetupControlsScreen } = await import("./screens/MatchSetupControlsScreen.js");
      const { isMatchSetupReady, loadMatchSetup } = await import("./match/matchSetupSession.js");
      const { navigateTo } = await import("./router.js");
      const setup = loadMatchSetup();
      if (!isMatchSetupReady(setup)) {
        navigateTo("match-setup-fighters");
        return;
      }
      mountMatchSetupControlsScreen(appRoot!);
    } else if (mode === "battle") {
      const { launchMatch } = await import("./game/App.js");
      const { mountFlaglineClash } = await import("./modes/flaglineClashView.js");
      const {
        applySetupToMatchSession,
        isMatchSetupReady,
        loadMatchSetup,
      } = await import("./match/matchSetupSession.js");
      const { navigateTo } = await import("./router.js");
      const setup = loadMatchSetup();
      if (!isMatchSetupReady(setup)) {
        navigateTo("match-setup-rules");
        return;
      }
      applySetupToMatchSession(setup);
      if (setup.mode === "flaglineClash" || setup.ruleset?.matchType === "flaglineClash") {
        mountFlaglineClash(appRoot!);
      } else {
        launchMatch(appRoot!, { skipSelect: true });
      }
    } else if (mode === "create-fighter") {
      const { mountCreateFighterScreen } = await import("./screens/CreateFighterScreen.js");
      mountCreateFighterScreen(appRoot!);
    } else if (mode === "custom-game") {
      const { mountCustomGameScreen } = await import("./screens/CustomGameScreen.js");
      mountCustomGameScreen(appRoot!);
    } else if (mode === "rulesets") {
      const { mountRulesetSelectScreen } = await import("./screens/RulesetSelectScreen.js");
      mountRulesetSelectScreen(appRoot!);
    } else if (mode === "fighter-select") {
      const { mountFighterSelectScreen } = await import("./screens/FighterSelectScreen.js");
      const { getMatchSetup, setMatchFighters } = await import("./match/matchSession.js");
      const { navigateTo } = await import("./router.js");
      mountFighterSelectScreen(appRoot!, (result) => {
        setMatchFighters(result.p1Fighter, result.p2Fighter);
        const setup = getMatchSetup();
        if (setup.customFlow) {
          navigateTo("controls-check");
        } else {
          navigateTo("match");
        }
      });
    } else if (mode === "controls-check") {
      const { mountControlsCheckScreen } = await import("./screens/ControlsCheckScreen.js");
      const { getMatchSetup } = await import("./match/matchSession.js");
      const { navigateTo } = await import("./router.js");
      const setup = getMatchSetup();
      if (!setup.p1Fighter || !setup.p2Fighter) {
        navigateTo("fighter-select");
        return;
      }
      mountControlsCheckScreen(
        appRoot!,
        { p1: setup.p1Fighter, p2: setup.p2Fighter },
        () => navigateTo("match"),
      );
    } else if (mode === "controls") {
      const { mountControlsScreen } = await import("./screens/ControlsScreen.js");
      mountControlsScreen(appRoot!);
    } else if (mode === "controls-remap") {
      const { mountInputRemapScreen } = await import("./screens/InputRemapScreen.js");
      const params = getRouteParams<{ action?: string; slot?: number }>();
      mountInputRemapScreen(appRoot!, {
        action: params.action as import("./input/actions.js").GameAction | undefined,
        slot: (params.slot as 1 | 2 | 3 | 4 | undefined) ?? 1,
      });
    } else if (mode === "match") {
      const { launchMatch } = await import("./game/App.js");
      const { getMatchSetup } = await import("./match/matchSession.js");
      const setup = getMatchSetup();
      launchMatch(appRoot!, {
        skipSelect: setup.customFlow && !!(setup.p1Fighter && setup.p2Fighter),
      });
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
    } else if (mode === "flagline-setup") {
      const { mountFlaglineClashSetupScreen } = await import("./screens/FlaglineClashSetupScreen.js");
      mountFlaglineClashSetupScreen(appRoot!);
    } else if (mode === "flagline-teams") {
      const { mountTeamSelectScreen } = await import("./screens/TeamSelectScreen.js");
      const { navigateTo } = await import("./router.js");
      mountTeamSelectScreen(appRoot!, () => navigateTo("flagline-clash"));
    } else if (mode === "flagline-clash") {
      const { mountFlaglineClash } = await import("./modes/flaglineClashView.js");
      mountFlaglineClash(appRoot!);
    } else if (mode === "feedback") {
      const { mountFeedbackScreen } = await import("./screens/FeedbackScreen.js");
      mountFeedbackScreen(appRoot!);
    } else if (mode === "career") {
      const { mountCareerScreen } = await import("./screens/CareerScreen.js");
      await mountCareerScreen(appRoot!);
    } else if (mode === "career-fighters") {
      const { mountFighterStatsScreen } = await import("./screens/FighterStatsScreen.js");
      await mountFighterStatsScreen(appRoot!);
    } else if (mode === "career-history") {
      const { mountMatchHistoryScreen } = await import("./screens/MatchHistoryScreen.js");
      await mountMatchHistoryScreen(appRoot!);
    } else if (mode === "career-replays") {
      const { mountReplayVaultScreen } = await import("./screens/ReplayVaultScreen.js");
      await mountReplayVaultScreen(appRoot!);
    } else if (mode === "career-saves") {
      const { mountSavedGamesScreen } = await import("./screens/SavedGamesScreen.js");
      await mountSavedGamesScreen(appRoot!);
    } else if (mode === "career-milestones") {
      const { mountMilestonesScreen } = await import("./screens/MilestonesScreen.js");
      await mountMilestonesScreen(appRoot!);
    } else if (mode === "replay") {
      const { mountReplayViewerScreen } = await import("./screens/ReplayViewerScreen.js");
      const params = getRouteParams<{ id?: string }>();
      const replayId = params.id ?? new URLSearchParams(window.location.hash.split("?")[1] ?? "").get("id");
      if (replayId) {
        await mountReplayViewerScreen(appRoot!, replayId);
      } else {
        appRoot!.innerHTML = "<p>Missing replay id.</p>";
      }
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
