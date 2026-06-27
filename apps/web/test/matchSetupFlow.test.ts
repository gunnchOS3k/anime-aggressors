import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { APP_ROUTES } from "../src/routes.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("match setup flow routes", () => {
  it("defines ordered setup hash routes", () => {
    assert.equal(APP_ROUTES.matchSetupRules, "#/match-setup/rules");
    assert.equal(APP_ROUTES.matchSetupStage, "#/match-setup/stage");
    assert.equal(APP_ROUTES.matchSetupFighters, "#/match-setup/fighters");
    assert.equal(APP_ROUTES.matchSetupControls, "#/match-setup/controls");
    assert.equal(APP_ROUTES.battle, "#/battle");
  });

  it("rules screen continues to map select", () => {
    const src = fs.readFileSync(
      path.join(webRoot, "src/screens/MatchSetupRulesScreen.ts"),
      "utf8",
    );
    assert.match(src, /navigateToHash\(APP_ROUTES\.matchSetupStage\)/);
    assert.match(src, /saveMatchSetup/);
  });

  it("map screen continues to fighter select", () => {
    const src = fs.readFileSync(
      path.join(webRoot, "src/screens/MatchSetupStageScreen.ts"),
      "utf8",
    );
    assert.match(src, /navigateToHash\(APP_ROUTES\.matchSetupFighters\)/);
    assert.match(src, /saveMatchSetup/);
  });

  it("fighter screen continues to controls check", () => {
    const src = fs.readFileSync(
      path.join(webRoot, "src/screens/MatchSetupFightersScreen.ts"),
      "utf8",
    );
    assert.match(src, /navigateToHash\(APP_ROUTES\.matchSetupControls\)/);
    assert.match(src, /saveMatchSetup/);
  });

  it("controls check starts battle via hash route", () => {
    const src = fs.readFileSync(
      path.join(webRoot, "src/screens/MatchSetupControlsScreen.ts"),
      "utf8",
    );
    assert.match(src, /navigateToHash\(APP_ROUTES\.battle\)/);
    assert.doesNotMatch(src, /location\.href\s*=\s*["']\/play/);
  });

  it("battle route redirects incomplete setup to rules", () => {
    const src = fs.readFileSync(path.join(webRoot, "src/main.ts"), "utf8");
    assert.match(src, /navigateTo\("match-setup-rules"\)/);
    assert.match(src, /isMatchSetupReady/);
  });
});
