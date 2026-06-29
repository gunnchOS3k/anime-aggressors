import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { renderHomeMarkup } from "../src/screens/homeScreenMarkup.ts";
import { APP_ROUTES } from "../src/routes.ts";

describe("home screen menu", () => {
  it("renders Godot combat as primary CTA", () => {
    const html = renderHomeMarkup();
    assert.match(html, /id="btn-godot-combat"/);
    assert.match(html, />Play Godot Combat Prototype</);
    assert.match(html, /menu-btn--hero/);
    assert.match(html, /ANIME AGGRESSORS/);
    assert.match(html, /Charge your aura/);
  });

  it("renders legacy Start Match CTA", () => {
    const html = renderHomeMarkup();
    assert.match(html, /id="btn-play-match"/);
    assert.match(html, /Legacy Web Prototype/);
  });

  it("includes animated scene canvas", () => {
    const html = renderHomeMarkup();
    assert.match(html, /id="menu-scene-canvas"/);
    assert.match(html, /arena-hub__canvas/);
  });

  it("groups secondary modes in carousel", () => {
    const html = renderHomeMarkup();
    assert.match(html, /Custom Game/);
    assert.match(html, /Flagline Clash/);
    assert.match(html, /Training Mode/);
    assert.match(html, /menu-carousel/);
  });

  it("Start Match routes to match setup rules", () => {
    const html = renderHomeMarkup();
    assert.match(html, new RegExp(`data-menu-route="${APP_ROUTES.matchSetupRules.replace("#", "\\#")}"`));
  });
});
