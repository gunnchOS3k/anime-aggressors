import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { ARENA_THEME } from "../src/ui/theme/arenaTheme.ts";
import { renderSetupFlowShell } from "../src/ui/setup/SetupFlowShell.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("setup flow theme", () => {
  it("arena theme defines setup route hashes", () => {
    assert.equal(ARENA_THEME.routes.rules, "#/match-setup/rules");
    assert.equal(ARENA_THEME.routes.stage, "#/match-setup/stage");
    assert.equal(ARENA_THEME.routes.fighters, "#/match-setup/fighters");
    assert.equal(ARENA_THEME.routes.controls, "#/match-setup/controls");
  });

  it("SetupFlowShell renders progress rail", () => {
    const html = renderSetupFlowShell({
      step: "rules",
      title: "Test",
      body: "<p>body</p>",
      footer: { backId: "b", backLabel: "Back" },
    });
    assert.match(html, /setup-shell/);
    assert.match(html, /setup-progress-rail/);
    assert.match(html, /setup-progress-step--active/);
  });

  for (const [screen, file] of [
    ["Rules", "MatchSetupRulesScreen.ts"],
    ["Stage", "MatchSetupStageScreen.ts"],
    ["Character", "CharacterSelectScreen.ts"],
    ["Controls", "MatchSetupControlsScreen.ts"],
  ] as const) {
    it(`${screen} screen uses SetupFlowShell`, () => {
      const src = fs.readFileSync(path.join(webRoot, "src/screens", file), "utf8");
      assert.match(src, /renderSetupFlowShell/);
    });
  }

  it("Custom Game screen uses SetupFlowShell", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/screens/CustomGameScreen.ts"), "utf8");
    assert.match(src, /renderSetupFlowShell/);
  });
});
