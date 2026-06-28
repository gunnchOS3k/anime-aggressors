import { renderFighterPortraitHtml, renderFighterPortraitSvg } from "./FighterPortraitFactory.ts";
import { PORTRAIT_CAMERA } from "./PortraitCamera.ts";

/** Portrait presentation layer — SVG busts today, Three.js bust hook later. */
export class FighterPortraitRenderer {
  renderHtml(fighterId: string, size = 72): string {
    return renderFighterPortraitHtml(fighterId, size);
  }

  renderSvg(fighterId: string, size = 72): string {
    return renderFighterPortraitSvg(fighterId, size);
  }

  getCameraConfig() {
    return PORTRAIT_CAMERA;
  }
}

export const fighterPortraitRenderer = new FighterPortraitRenderer();
