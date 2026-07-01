import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { renderHomeMarkup } from "../src/screens/homeScreenMarkup.ts";
import { APP_ROUTES } from "../src/routes.ts";

describe("home screen menu", () => {
  it("renders Play Demo as primary CTA", () => {
    const html = renderHomeMarkup();
    assert.match(html, /id="btn-quick-match"/);
    assert.match(html, />Play Demo</);
    assert.match(html, /menu-btn--hero/);
    assert.match(html, /ANIME AGGRESSORS/);
    assert.match(html, /Play Demo/);
  });

  it("renders custom match setup as secondary CTA", () => {
    const html = renderHomeMarkup();
    assert.match(html, /id="btn-play-match"/);
    assert.match(html, /Custom Match Setup/);
  });

  it("includes animated scene canvas", () => {
    const html = renderHomeMarkup();
    assert.match(html, /id="menu-scene-canvas"/);
    assert.match(html, /arena-hub__canvas/);
  });

  it("groups secondary modes in carousel without derby/flagline", () => {
    const html = renderHomeMarkup();
    const carousel = html.match(/<div class="menu-carousel"[\s\S]*?<\/div>\s*<\/div>/)?.[0] ?? "";
    assert.match(carousel, /Custom Game/);
    assert.match(carousel, /Training Mode/);
    assert.match(carousel, /Fighter Select/);
    assert.match(carousel, /Stage Select/);
    assert.doesNotMatch(carousel, /Impact Dummy Derby/);
    assert.doesNotMatch(carousel, /Flagline Clash/);
  });

  it("labs panel lists experimental modes", () => {
    const html = renderHomeMarkup();
    assert.match(html, /Godot Combat Prototype/);
    assert.match(html, /Impact Dummy Derby/);
    assert.match(html, /Flagline Clash/);
  });

  it("Quick Match routes to battle hash", () => {
    const html = renderHomeMarkup();
    assert.match(html, new RegExp(`data-menu-route="${APP_ROUTES.battle.replace("#", "\\#")}"`));
  });
});
