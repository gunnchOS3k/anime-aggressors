import { APP_ROUTES, navigateToHash } from "../routes.js";
import { mountMatchSetupCharacterSelect } from "./CharacterSelectScreen.js";

export function mountMatchSetupFightersScreen(root: HTMLElement): void {
  mountMatchSetupCharacterSelect(root);
}

export { mountCharacterSelectScreen, mountMatchSetupCharacterSelect } from "./CharacterSelectScreen.js";
export type { CharacterSelectResult, FighterSelectResult } from "./CharacterSelectScreen.js";
