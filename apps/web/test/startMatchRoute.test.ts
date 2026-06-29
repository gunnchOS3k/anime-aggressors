import { describe, it } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { APP_ROUTES } from "../src/routes.ts";
import { renderHomeMarkup } from "../src/screens/homeScreenMarkup.ts";

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

describe("start match route", () => {
  it("APP_ROUTES.matchSetupRules is the setup entry", () => {
    assert.equal(APP_ROUTES.matchSetupRules, "#/match-setup/rules");
  });

  it("HomeScreen legacy Start Match links to match setup rules", () => {
    const html = renderHomeMarkup();
    assert.match(html, /id="btn-play-match"/);
    assert.match(html, /Legacy Web Prototype/);
    assert.match(html, /#\/match-setup\/rules/);
  });

  it("main menu config maps btn-play-match to match-setup-rules", () => {
    const config = fs.readFileSync(path.join(webRoot, "src/ui/mainMenuConfig.ts"), "utf8");
    assert.match(config, /btn-play-match/);
    assert.match(config, /match-setup-rules/);
  });
});
