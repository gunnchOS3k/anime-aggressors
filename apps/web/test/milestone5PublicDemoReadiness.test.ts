import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { APP_ROUTES, hashToMode } from "../src/routes.ts";
import { renderHomeMarkup } from "../src/screens/homeScreenMarkup.ts";
import {
  dismissDemoOnboarding,
  isDemoOnboardingDismissed,
  renderDemoOnboardingHtml,
  resetDemoOnboarding,
} from "../src/demo/demoOnboarding.ts";
import { getAudioVolume, isAudioMuted, setAudioMuted, setAudioVolume } from "../src/demo/audioSettings.ts";
import { renderCharacterTile } from "../src/ui/CharacterTile.ts";
import { buildSelectableRoster } from "../src/characterSelect/characterSelectState.ts";
import { listProductionStageIds } from "@anime-aggressors/game-core";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");

function withMockStorage(run: () => void): void {
  const store = new Map<string, string>();
  const previous = globalThis.localStorage;
  globalThis.localStorage = {
    getItem: (k) => store.get(k) ?? null,
    setItem: (k, v) => {
      store.set(k, v);
    },
    removeItem: (k) => {
      store.delete(k);
    },
    clear: () => store.clear(),
    key: () => null,
    length: 0,
  } as Storage;
  try {
    run();
  } finally {
    globalThis.localStorage = previous;
  }
}

describe("Milestone 5 — public demo readiness", () => {
  it("home CTA routes to battle hash", () => {
    const html = renderHomeMarkup();
    assert.match(html, /id="btn-quick-match"/);
    assert.match(html, />Play Demo</);
    assert.match(html, new RegExp(`data-menu-route="${APP_ROUTES.battle.replace("#", "\\#")}"`));
  });

  it("fighter select and stage select are on home carousel", () => {
    const html = renderHomeMarkup();
    assert.match(html, /id="btn-fighter-select"/);
    assert.match(html, /id="btn-stage-select"/);
    assert.equal(hashToMode(APP_ROUTES.fighterSelect), "fighter-select");
    assert.equal(hashToMode(APP_ROUTES.stageSelect), "stage-select");
  });

  it("about route is registered", () => {
    assert.equal(hashToMode(APP_ROUTES.about), "about");
    const html = renderHomeMarkup();
    assert.match(html, /id="btn-about"/);
  });

  it("labs panel is separate from main carousel", () => {
    const html = renderHomeMarkup();
    const carousel = html.match(/<div class="menu-carousel"[\s\S]*?<\/div>\s*<\/div>/)?.[0] ?? "";
    assert.doesNotMatch(carousel, /Godot Combat/);
    assert.match(html, /Labs &amp; Debug/);
  });

  it("production and preview badges render on fighter tiles", () => {
    const roster = buildSelectableRoster();
    const ember = roster.find((f) => f.id === "ember-vale")!;
    const vesper = roster.find((f) => f.id === "vesper-nyx")!;
    assert.match(renderCharacterTile({ fighter: ember, state: "default" }), /cs-tile-badge--production/);
    assert.match(renderCharacterTile({ fighter: vesper, state: "default" }), /cs-tile-badge--preview/);
  });

  it("demo onboarding html explains core mechanics", () => {
    const html = renderDemoOnboardingHtml();
    assert.match(html, /knock your opponent/i);
    assert.match(html, /Stocks/);
    assert.match(html, /Shield/);
    assert.match(html, />\s*H\s*</);
    assert.match(html, /F2/);
  });

  it("demo onboarding dismissal uses localStorage key", () => {
    withMockStorage(() => {
      resetDemoOnboarding();
      assert.equal(isDemoOnboardingDismissed(), false);
      dismissDemoOnboarding();
      assert.equal(isDemoOnboardingDismissed(), true);
      resetDemoOnboarding();
      assert.equal(isDemoOnboardingDismissed(), false);
    });
  });

  it("audio settings persist volume and mute", () => {
    withMockStorage(() => {
      setAudioVolume(0.5);
      setAudioMuted(true);
      assert.equal(getAudioVolume(), 0.5);
      assert.equal(isAudioMuted(), true);
      setAudioMuted(false);
      setAudioVolume(1);
    });
  });

  it("production stage ids count is three", () => {
    assert.equal(listProductionStageIds().length, 3);
  });

  it("M5 documentation files exist", () => {
    const docs = [
      "docs/MILESTONE_5_PUBLIC_DEMO_READINESS.md",
      "docs/ENGINE_MIGRATION_DECISION.md",
      "docs/DEPLOYMENT.md",
      "docs/PUBLIC_DEMO_CHECKLIST.md",
      "docs/KNOWN_ISSUES.md",
      "docs/RELEASE_NOTES_M5_PUBLIC_DEMO.md",
      "docs/TRAILER_CAPTURE_CHECKLIST.md",
      "docs/playtest/2026-07-01-m5-public-demo-readiness.md",
    ];
    for (const doc of docs) {
      assert.ok(fs.existsSync(path.join(repoRoot, doc)), `missing ${doc}`);
    }
  });

  it("engine migration doc states no migration in M5", () => {
    const md = fs.readFileSync(path.join(repoRoot, "docs/ENGINE_MIGRATION_DECISION.md"), "utf8");
    assert.match(md, /does not authorize or perform engine migration/i);
    assert.match(md, /Recommendation/i);
    assert.match(md, /TypeScript/i);
  });
});
