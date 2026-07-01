import { APP_ROUTES, navigateToHash } from "../routes.js";
import { mountCharacterSelectScreen } from "./CharacterSelectScreen.js";
import {
  applySetupToMatchSession,
  loadMatchSetup,
  saveMatchSetup,
} from "../match/matchSetupSession.ts";
import { navigateHome } from "../router.js";

export function mountDemoFighterSelectScreen(root: HTMLElement): void {
  const setup = loadMatchSetup();

  mountCharacterSelectScreen(root, {
    title: "Fighter Select",
    setupSummary: "All 7 fighters selectable — production vs preview badges shown.",
    continueLabel: "Start Match",
    backLabel: "← Home",
    onBack: () => navigateHome(),
    onContinue: (result) => {
      const next = {
        ...setup,
        fighters: [
          { playerId: 0, fighterId: result.p1.id, fighter: result.p1 },
          { playerId: 1, fighterId: result.p2.id, fighter: result.p2 },
        ],
      };
      saveMatchSetup(next);
      applySetupToMatchSession(next);
      navigateToHash(APP_ROUTES.battle);
    },
  });
}
